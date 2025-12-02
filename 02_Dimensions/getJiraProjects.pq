let
    getJiraProjects =
        (
            authorizationToken as text
        ) =>
        let
            defaultProjectsPageSize = 100,

            jiraRequest = (startAt as number) =>
                let
                    query =
                        [
                            startAt = Text.From(startAt) ?? "0",
                            maxResults = Text.From(defaultProjectsPageSize),
                            expand = "insight, lead"
                        ],
                    getRequest =
                        Json.Document(
                            Web.Contents(
                                jiraHost,
                                [
                                    RelativePath = "rest/api/3/project/search",
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
                                startAt = i[startAt] + defaultProjectsPageSize,
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
                        key = text,
                        name = text,
                        projectTypeKey = nullable text,
                        style = nullable text,
                        isPrivate = nullable logical,
                        entityId = nullable text,
                        uuid = nullable text,

                        lead_accountId = nullable text,
                        lead_active = nullable logical,

                        projectCategory_id = nullable text,
                        projectCategory_name = nullable text,
                        projectCategory_description = nullable text,

                        insight_totalIssueCount = nullable Int64.Type,
                        insight_lastIssueUpdateTime = nullable datetimezone
                    ],
                    List.Transform(
                        listResult,
                        each
                                {
                                    Number.From([id]?),
                                    [key]?,
                                    [name]?,
                                    [projectTypeKey]?,
                                    [style]?,
                                    [isPrivate]?,
                                    [entityId]?,
                                    [uuid]?,

                                    [lead]?[accountId]?,
                                    [lead]?[active]?,

                                    [projectCategory]?[id]?,
                                    [projectCategory]?[name]?,
                                    [projectCategory]?[description]?,

                                    Number.From([insight]?[totalIssueCount]?),
                                    DateTimeZone.From([insight]?[lastIssueUpdateDate]?)
                                }
                    )
                )
        in
            projectsTable,

    functionType =
        type function
        (
            

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
            Documentation.Name = "get-jira-projects",
            Documentation.Description = "Get Jira projects via GET /rest/api/3/project/search. The function pages through projects using startAt and an internal maxResults value of 100 until there are no more results. The result is returned as a typed table with flattened lead, projectCategory and insight fields. Note: Provide the jiraHost parameter when calling this function.",
            Documentation.Source = "https://www.vojtechsima.com/",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Load projects with internal paging (page size 100).",
                        Code = "getJiraProjects(""Basic user:token"")",
                        Result = "Returns a table of Jira projects with flattened lead, projectCategory and insight fields."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getJiraProjects,
        functionType
    )