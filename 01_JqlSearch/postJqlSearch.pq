let
    postJqlSearch =
        (
            jiraHost as text,
            authorizationToken as text,
            resultMode as text,
            optional jql as nullable text,
            optional fields as nullable text
        ) =>
        let
            defaultPostJqlPageSize = 100,

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
                            maxResults = Text.From(defaultPostJqlPageSize),
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
                                    fields = [fields]
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
                        fields = record
                    ],
                    List.Transform(
                        listResult,
                        each
                            {
                                Number.From([id]?),
                                [key]?,
                                [fields]?
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
                        Documentation.FieldDescription = "Comma separated list of fields to return from Jira. Internally this is sent as a list in the POST body. Keep this list limited and use the result as a fact table that you relate to a separate work items dimension.",
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
            Documentation.Name = "post-jql-search",
            Documentation.Description = "Post JQL search for Jira work items via POST /rest/api/3/search/jql. The Jira expand parameter is not exposed, so the function returns only the requested fields. The resultMode parameter controls the shape of the result. When resultMode is ""table"" the function returns a table, for any other value it returns a list of records.",
            Documentation.Source = "https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Basic use with default parameters and list result.",
                        Code = "postJqlSearch(""https://tenant.atlassian.net"", ""Basic user:token"", ""list"")",
                        Result = "Returns a list of records, each containing id, key and fields for matching Jira work items."
                    ],
                    [
                        Description = "Return a table using a custom JQL filter and default fields.",
                        Code = "postJqlSearch(""https://tenant.atlassian.net"", ""Basic user:token"", ""table"", ""project = 'DEMO' AND status = 'Done'"")",
                        Result = "Returns a table with columns id, key and fields."
                    ],
                    [
                        Description = "Return a table with all supported optional parameters specified.",
                        Code = "postJqlSearch(""https://tenant.atlassian.net"", ""Basic user:token"", ""table"", ""assignee = currentUser()"", ""summary, created, status, assignee"")",
                        Result = "Returns a table of Jira work items that match the JQL, with the selected fields, combining pages using the internal default page size."
                    ]
                }
        ]
in
    Value.ReplaceType(
        postJqlSearch,
        functionType
    )