let
    getJqlSearch =
        (
            authorizationToken as text,
            resultMode as text,
            optional jql as nullable text,
            optional fields as nullable text
        ) =>
        let
            defaultJqlPageSize = 100,

            jiraRequest =
                (
                    optional jql as nullable text,
                    optional fields as nullable text,
                    optional nextPageToken as nullable text
                ) =>
                let
                    query =
                        [
                            jql = jql ?? "assignee = currentUser()",
                            fields = fields ?? "summary, created, status",
                            maxResults = Text.From(defaultJqlPageSize),
                            nextPageToken = nextPageToken ?? ""
                        ],
                    getRequest =
                        Json.Document(
                            Web.Contents(
                                jiraHost,
                                [
                                    RelativePath = "/rest/api/3/search/jql",
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

            prepareParams = { jql, fields },

            grabber =
                List.Generate(
                    () =>
                        [
                            request = Function.Invoke(jiraRequest, prepareParams),
                            next = request[nextPageToken]?,
                            issues = request[issues]?,
                            index = 0
                        ],
                    (i) =>
                        i[next]? <> null
                        or i[index] = 0,
                    (i) =>
                        [
                            request = Function.Invoke(jiraRequest, prepareParams & { next }),
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
                        Documentation.FieldDescription = "JQL query that filters work items. Leave null to use ""assignee = currentUser()"".",
                        Documentation.SampleValues =
                            {
                                "assignee = currentUser()"
                            }
                    ]
                ),

            optional fields as
                (type nullable text meta
                    [
                        Documentation.FieldCaption = "fields",
                        Documentation.FieldDescription = "Comma separated list of fields to return from Jira. The Jira expand parameter is not exposed, so you only get the fields you specify.",
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
            Documentation.Name = "get-jql-search",
            Documentation.Description = "Get work items from Jira using JQL via /rest/api/3/search/jql. The Jira expand query parameter is intentionally not supported, so the function always returns only the requested fields. The resultMode parameter controls the shape of the result. When resultMode is ""table"" the function returns a table, for any other value it returns a list of records. Note: Provide the jiraHost parameter when calling this function.",
            Documentation.Source = "https://www.vojtechsima.com",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Basic use with default parameters and list result.",
                            Code = "getJqlSearch(""Basic user:token"", ""list"")",
                        Result = "Returns a list of records, each containing id, key and fields for matching Jira work items."
                    ],
                    [
                        Description = "Return a table using a custom JQL filter and default fields.",
                        Code = "getJqlSearch(""Basic user:token"", ""table"", ""project = 'DEMO' AND status = 'Done'"")",
                        Result = "Returns a table with columns id, key and fields."
                    ],
                    [
                        Description = "Return a table with all supported optional parameters specified.",
                        Code = "getJqlSearch(""Basic user:token"", ""table"", ""assignee = currentUser()"", ""summary, created, status, assignee"")",
                        Result = "Returns a table of Jira work items that match the JQL, with the selected fields. The result is assembled from multiple pages that each use the internal default page size."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getJqlSearch,
        functionType
    )