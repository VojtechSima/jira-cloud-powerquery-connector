let
    postJqlSearchWithChangelog =
        (
            authorizationToken as text,
            resultMode as text,
            optional jql as nullable text,
            optional fields as nullable text
        ) =>
        let
            defaultPostJqlChangelogPageSize = 100,

            jiraRequest =
                (
                    optional nextPageToken as nullable text
                ) =>
                let
                    query =
                        [
                            jql = jql ?? "assignee = currentUser()",
                            fields =
                                if fields = null
                                then
                                    { "summary", "created", "status" }
                                else
                                    List.Transform(
                                        Text.Split(fields, ","),
                                        each Text.Trim(Text.Clean(_))
                                    ),
                            maxResults = Text.From(defaultPostJqlChangelogPageSize),
                            expand = "changelog",
                            nextPageToken = nextPageToken ?? ""
                        ],
                    getRequest =
                        Json.Document(
                            Web.Contents(
                                jiraHost,
                                [
                                    RelativePath = "/rest/api/3/search/jql",
                                    Content = Json.FromValue(query),
                                    Headers =
                                        [
                                            Accept = "application/json",
                                            #"Content-Type" = "application/json",
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
                            request = jiraRequest(),
                            next = request[nextPageToken]?,
                            issues = request[issues]?,
                            index = 0
                        ],
                    (i) =>
                        i[next]? <> null
                        or i[index] = 0,
                    (i) =>
                        [
                            request = jiraRequest(next),
                            next = i[request]?[nextPageToken]?,
                            issues = request[issues]?,
                            index = i[index] + 1
                        ],
                    (i) =>
                        List.Transform(
                            i[request]?[issues]?,
                            each
                                [
                                    id = [id],
                                    key = [key],
                                    fields = [fields],
                                    changelog = [changelog]
                                ]
                        )
                ),

            listResult = List.Combine(grabber),

            tableResult =
                #table(
                    type table
                    [
                        id = Int64.Type,
                        key = text,
                        fields = record,
                        changelog = record
                    ],
                    List.Transform(
                        listResult,
                        each
                            {
                                Number.From([id]?),
                                [key]?,
                                [fields]?,
                                [changelog]?
                            }
                    )
                ),

            result =
                if resultMode = "table"
                then tableResult
                else listResult
        in
            result,

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
                ),

            resultMode as
                (type text meta
                    [
                        Documentation.FieldCaption = "resultMode",
                        Documentation.FieldDescription = "Shape of the result. When resultMode = ""table"" the function returns a table. For any other value (including ""list"" or null) it returns a list of records.",
                        Documentation.AllowedValues = { "table", "list" },
                        Documentation.SampleValues = { "table", "list" }
                    ]
                ),

            optional jql as
                (type nullable text meta
                    [
                        Documentation.FieldCaption = "jql",
                        Documentation.FieldDescription = "JQL query that filters work items. Leave null to use ""assignee = currentUser()"". This POST variant is recommended for long or complex JQL expressions to avoid URL length limits.",
                        Documentation.SampleValues =
                            {
                                "assignee = currentUser()",
                                "project = 'DEMO' AND status = 'Done'"
                            }
                    ]
                ),

            optional fields as
                (type nullable text meta
                    [
                        Documentation.FieldCaption = "fields",
                        Documentation.FieldDescription = "Comma separated list of fields to return from Jira. Internally this is sent as a list in the POST body. The function always uses expand = ""changelog"", so keep this to a limited set of fields and use the result as a fact table that you connect to a separate dim WorkItems table.",
                        Documentation.SampleValues =
                            {
                                "summary, created, status",
                                "summary, created, status, assignee"
                            }
                    ]
                )
        )
        as any meta
        [
            Documentation.Name = "post-jql-search-with-changelog",
            Documentation.Description = "Post JQL search for Jira work items via POST /rest/api/3/search/jql with expand = ""changelog"" always applied. Because changelog can be large, this function is intended for narrower field sets and is best used as a fact table that you relate to a dim WorkItems table loaded by a simpler query. The resultMode parameter controls the shape of the result. When resultMode is ""table"" the function returns a table, for any other value it returns a list of records. Note: Provide the jiraHost parameter when calling this function.",
            Documentation.Source = "https://www.vojtechsima.com",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Basic use with default parameters and list result.",
                        Code = "postJqlSearchWithChangelog(""Basic user:token"", ""list"")",
                        Result = "Returns a list of records, each containing id, key, fields and changelog for matching Jira work items."
                    ],
                    [
                        Description = "Return a table using a custom JQL filter and default fields.",
                        Code = "postJqlSearchWithChangelog(""Basic user:token"", ""table"", ""project = 'DEMO' AND status = 'Done'"")",
                        Result = "Returns a table with columns id, key, fields and changelog."
                    ],
                    [
                        Description = "Return a table with all supported optional parameters specified. Use as a fact table and relate it to a dim WorkItems table.",
                        Code = "postJqlSearchWithChangelog(""Basic user:token"", ""table"", ""assignee = currentUser()"", ""summary, created, status, assignee"")",
                        Result = "Returns a table of Jira work items that match the JQL, including changelog, with pages combined using the internal default page size."
                    ]
                }
        ]
in
    Value.ReplaceType(
        postJqlSearchWithChangelog,
        functionType
    )