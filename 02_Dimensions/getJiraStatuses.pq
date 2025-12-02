let
    getJiraStatuses =
        (
            authorizationToken as text
        ) =>
        let
            statuses =
                Json.Document(
                    Web.Contents(
                        jiraHost,
                        [
                            RelativePath = "rest/api/3/status",
                            Headers =
                                [
                                    Accept = "application/json",
                                    Authorization = authorizationToken
                                ]
                        ]
                    )
                ),
            statusesTable =
                #table(
                    type table
                    [
                        id = Int64.Type,
                        description = text,
                        name = text,
                        untranslatedName = text,
                        statusCategory_id = Int64.Type,
                        statusCategory_key = text,
                        statusCategory_name = text,
                        statusCategory_colorName = text
                    ],
                    List.Transform(
                        statuses,
                        each
                                {
                                    Number.From([id]?),
                                    [description]?,
                                    [name]?,
                                    [untranslatedName]?,
                                    Number.From([statusCategory]?[id]?),
                                    [statusCategory]?[key]?,
                                    [statusCategory]?[name]?,
                                    [statusCategory]?[colorName]?
                                }
                    )
                )
        in
            statusesTable,

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
            Documentation.Name = "get-jira-statuses",
            Documentation.Description = "Get Jira workflow statuses via GET /rest/api/3/status. The function returns all statuses associated with active workflows, including status category information (id, key, name and colorName). Note: Provide the jiraHost parameter when calling this function.",
            Documentation.Source = "https://www.vojtechsima.com/",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Load all workflow statuses from Jira.",
                        Code = "getJiraStatuses(""Basic user:token"")",
                        Result = "Returns a table of Jira statuses including id, description, name, untranslatedName and statusCategory fields."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getJiraStatuses,
        functionType
    )