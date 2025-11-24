let
    getJiraResolutions =
        (
            jiraHost as text,
            authorizationToken as text
        ) =>
        let
            resolutions =
                Json.Document(
                    Web.Contents(
                        jiraHost,
                        [
                            RelativePath = "rest/api/3/resolution",
                            Headers =
                                [
                                    Accept = "application/json",
                                    Authorization = authorizationToken
                                ]
                        ]
                    )
                ),
            resolutionsTable =
                #table(
                    type table
                    [
                        id = Int64.Type,
                        description = text,
                        name = text
                    ],
                    List.Transform(
                        resolutions,
                        each
                                {
                                    Number.From([id]?),
                                    [description]?,
                                    [name]?
                                }
                    )
                )
        in
            resolutionsTable,

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
            Documentation.Name = "get-jira-resolutions",
            Documentation.Description = "Get Jira resolutions via GET /rest/api/3/resolution. The function returns all issue resolution values as a typed table with id, description and name fields.",
            Documentation.Source = "https://www.vojtechsima.com/",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Load all resolutions from Jira.",
                        Code = "getJiraResolutions(""https://tenant.atlassian.net"", ""Basic user:token"")",
                        Result = "Returns a table of Jira resolutions including id, description and name."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getJiraResolutions,
        functionType
    )