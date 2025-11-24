let
    getJiraProjects =
        (
            jiraHost as text,
            authorizationToken as text
        ) =>
        let
            defaultBoardsPageSize = 50,

            jiraRequest = (startAt as number) =>
                let
                    query =
                        [
                            startAt = Text.From(startAt) ?? "0",
                            maxResults = Text.From(defaultBoardsPageSize)
                        ],
                    getRequest =
                        Json.Document(
                            Web.Contents(
                                jiraHost,
                                [
                                    RelativePath = "rest/agile/1.0/board",
                                    Query = query,
                                    Headers =
                                        [
                                            Accept = "application/json",
                                            Authorization = authorizationToken
                                        ]
                                ]
                            )
                        )
                in
                    getRequest,

            grabber =
                List.Generate(
                    () =>
                            [
                                startAt = 0,
                                result = jiraRequest(0),
                                total = result[total]?
                            ],
                    (i) =>
                        i[startAt]? <= i[total]?,
                    (i) =>
                            [
                                startAt = i[startAt] + defaultBoardsPageSize,
                                result = jiraRequest(startAt),
                                total = result[total]?
                            ],
                    (i) => i[result]?[values]?
                ),

            listResult = List.Combine(grabber),

            projectsTable =
                #table(
                    type table
                    [
                        id = Int64.Type,
                        name = text,
                        isPrivate = logical,

                        location_projectId = nullable Int64.Type,
                        location_displayName = nullable text,
                        location_projectName = nullable text,
                        location_projectKey = nullable text,
                        location_projectTypeKey = nullable text,
                        location_name = nullable text
                    ],
                    List.Transform(
                        listResult,
                        each
                                {
                                    Number.From([id]?),
                                    [name]?,
                                    [isPrivate]?,

                                    Number.From([location]?[projectId]?),
                                    [location]?[displayName]?,
                                    [location]?[projectName]?,
                                    [location]?[projectKey]?,
                                    [location]?[projectTypeKey]?,
                                    [location]?[name]?
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
            Documentation.Name = "get-jira-boards",
            Documentation.Description = "Get Jira boards via GET /rest/agile/1.0/board. The function pages through boards using startAt and an internal maxResults value of 50 until all results are scanned based on the total field returned by the API. The result is returned as a typed table with board fields and flattened location fields (projectId, displayName, projectName, projectKey, projectTypeKey and name).",
            Documentation.Source = "https://www.vojtechsima.com/",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Load boards with the internal default page size (50).",
                        Code = "getJiraProjects(""https://tenant.atlassian.net"", ""Basic user:token"")",
                        Result = "Returns a table of Jira boards with board level fields and flattened location fields."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getJiraProjects,
        functionType
    )