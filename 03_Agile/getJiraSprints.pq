let
    getJiraSprints =
        (
            jiraHost as text,
            authorizationToken as text
        ) =>
        let
            defaultAgilePageSize = 50,

            jiraAgileOffsetRequest = (endpointPath as text, startAt as number, maxResults as number) =>
                let
                    basePath = "rest/agile/1.0/",
                    query =
                        [
                            startAt = Text.From(startAt) ?? "0",
                            maxResults = Text.From(defaultAgilePageSize)
                        ],
                    request =
                        Web.Contents(
                            jiraHost,
                            [
                                RelativePath = basePath & endpointPath,
                                ManualStatusHandling = { 400 },
                                Query = query,
                                Headers =
                                    [
                                        Accept = "application/json",
                                        Authorization = authorizationToken
                                    ]
                            ]
                        ),
                    responseStatus = Value.Metadata(request)[#"Response.Status"]?,
                    errorHandling = if responseStatus = 200 then Json.Document(request) else null
                in
                    errorHandling,

            offsetPaginator = (endpointPath as text) =>
                List.Generate(
                    () =>
                            [
                                startAt = 0,
                                result = jiraAgileOffsetRequest(endpointPath, startAt, defaultAgilePageSize),
                                total = result[total]?
                            ],
                    (i) =>
                        (i[startAt]? < i[total]?) ?? false,
                    (i) =>
                            [
                                startAt = i[startAt]? + defaultAgilePageSize,
                                result = jiraAgileOffsetRequest(endpointPath, startAt, defaultAgilePageSize),
                                total = result[total]?
                            ],
                    (i) => i[result]?[values]?
                ),

            boardListResult = List.Combine(offsetPaginator("board")),
            getBoardIdsAndBuffer = List.Buffer(List.Transform(boardListResult, each [id]?)),
            getSprints = List.Transform(getBoardIdsAndBuffer, each List.Combine(offsetPaginator("board/" & Text.From(_) & "/sprint"))),
            sprintListResult = List.Combine(getSprints),

            projectsTable =
                #table(
                    type table
                    [
                        id = Int64.Type,
                        state = text,
                        name = text,
                        startDate = datetimezone,
                        endDate = datetimezone,
                        completeDate = datetimezone,
                        originBoardId = Int64.Type,
                        goal = text
                    ],
                    List.Transform(
                        sprintListResult,
                        each
                                {
                                    Number.From([id]?),
                                    [state]?,
                                    [name]?,
                                    DateTimeZone.From([startDate]?),
                                    DateTimeZone.From([endDate]?),
                                    DateTimeZone.From([completeDate]?),
                                    Number.From([originBoardId]?),
                                    [goal]?
                                }
                    )
                )
        in
            projectsTable,

    functionType =
        type function
        (
            jiraHost as
                (type text meta
                    [
                        Documentation.FieldCaption = "jiraHost",
                        Documentation.FieldDescription = "Jira cloud host in the form ""https://tenant.atlassian.net"".",
                        Documentation.SampleValues = { "https://tenant.atlassian.net" }
                    ]
                ),

            authorizationToken as
                (type text meta
                    [
                        Documentation.FieldCaption = "authorizationToken",
                        Documentation.FieldDescription = "Value for the Authorization header, for example ""Basic user:token"".",
                        Documentation.SampleValues = { "Basic user:token" }
                    ]
                )
        )
        as any meta
        [
            Documentation.Name = "get-jira-sprints",
            Documentation.Description = "Get Jira sprints via /rest/agile/1.0/board and /rest/agile/1.0/board/{boardId}/sprint. The function first loads all boards, then pages through sprints for each board using startAt and an internal page size of 50 until all results are scanned based on the total field returned by the API. The result is returned as a typed table with sprint fields (id, state, name, startDate, endDate, completeDate, originBoardId and goal).",
            Documentation.Source = "Jira Cloud Agile REST API documentation for board and sprint endpoints.",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Load all sprints for all boards with internal paging (page size 50).",
                        Code = "getJiraSprints(""https://tenant.atlassian.net"", ""Basic user:token"")",
                        Result = "Returns a table of Jira sprints across all boards, including state, dates and originBoardId."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getJiraSprints,
        functionType
    )