let
    getJiraUsers =
        (
            authorizationToken as text
        ) =>
        let
            defaultUsersPageSize = 1000,
            defaultUsersMaxRequests = 200,

            jiraRequest =
                (startAt as number) =>
                let
                    query =
                        [
                            maxResults = Text.From(defaultUsersPageSize),
                            startAt = Text.From(startAt)
                        ],
                    getRequest =
                        Json.Document(
                            Web.Contents(
                                jiraHost,
                                [
                                    RelativePath = "rest/api/3/users/search",
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
                                result = jiraRequest(startAt),
                                index = 0
                            ],
                    (i) =>
                        not List.IsEmpty(i[result])
                        and i[index] < defaultUsersMaxRequests,
                    (i) =>
                            [
                                startAt = i[startAt] + defaultUsersPageSize,
                                result = jiraRequest(startAt),
                                index = i[index] + 1
                            ],
                    (i) => i[result]
                ),

            listResult = List.Combine(grabber),

            usersTable =
                #table(
                    type table
                    [
                        accountId = text,
                        accountType = text,
                        emailAddress = text,
                        displayName = text,
                        active = logical
                    ],
                    List.Transform(
                        listResult,
                        each
                            {
                                [accountId]?,
                                [accountType]?,
                                [emailAddress]?,
                                [displayName]?,
                                [active]?
                            }
                    )
                )
        in
            usersTable,

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
            Documentation.Name = "get-jira-users",
            Documentation.Description = "Get Jira users via GET /rest/api/3/users/search. The function pages through users using startAt and maxResults until a page comes back empty or the internal maxRequests limit is reached. Internally it uses a page size of 1000 users and a maximum of 200 paged requests. The result is always returned as a typed table with accountId, accountType, emailAddress, displayName and active columns. Note: Provide the jiraHost parameter when calling this function.",
            Documentation.Source = "https://www.vojtechsima.com",
            Documentation.Version = "1.1",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Load users with internal defaults (page size 1000, up to 200 requests).",
                        Code = "getJiraUsers(""Basic user:token"")",
                        Result = "Returns a table of Jira users with columns accountId, accountType, emailAddress, displayName and active."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getJiraUsers,
        functionType
    )