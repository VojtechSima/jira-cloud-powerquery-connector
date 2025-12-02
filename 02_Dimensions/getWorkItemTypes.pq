let
    getWorkItemTypes =
        (
            authorizationToken as text
        ) =>
        let
            statuses =
                Json.Document(
                    Web.Contents(
                        jiraHost,
                        [
                            RelativePath = "rest/api/3/issuetype",
                            Headers =
                                [
                                    Accept = "application/json",
                                    Authorization = authorizationToken
                                ]
                        ]
                    )
                ),
            workItemTypesTable =
                #table(
                    type table
                    [
                        id = Int64.Type,
                        description = text,
                        name = text,
                        untranslatedName = text,
                        subtask = logical,
                        hierarchyLevel = Int64.Type
                    ],
                    List.Transform(
                        statuses,
                        each
                            {
                                Number.From([id]?),
                                [description]?,
                                [name]?,
                                [untranslatedName]?,
                                [subtask]?,
                                Number.From([hierarchyLevel]?)
                            }
                    )
                )
        in
            workItemTypesTable,

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
            Documentation.Name = "get-jira-work-item-types",
            Documentation.Description = "Get Jira work item types via GET /rest/api/3/issuetype. The function returns all work item types visible to the user as a typed table with fields id, description, name, untranslatedName, subtask and hierarchyLevel. Note: Provide the jiraHost parameter when calling this function.",
            Documentation.Source = "https://www.vojtechsima.com/",
            Documentation.Version = "1.0",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Load all work item types from Jira using basic authentication with user and token.",
                        Code = "getWorkItemTypes(""Basic user:token"")",
                        Result = "Returns a table of Jira work item types including id, description, name, untranslatedName, subtask and hierarchyLevel."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getWorkItemTypes,
        functionType

    )
