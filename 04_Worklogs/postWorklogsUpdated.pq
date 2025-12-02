let
    postWorklogsUpdated =
        (
            authorizationToken as text,
            optional fromDateAsText as nullable text
        ) =>
        let
            dateAsTextToUnixMs =
                if fromDateAsText <> null and Text.Trim(fromDateAsText) <> ""
                then
                    Duration.TotalSeconds(
                        DateTime.From(fromDateAsText)
                        - #datetime(1970, 1, 1, 0, 0, 0)
                    ) * 1000
                else
                    0,

            maxLimitForWorklogPage = 1000,

            worklog = (since as number) =>
                Json.Document(
                    Web.Contents(
                        jiraHost,
                        [
                            RelativePath = "rest/api/3/worklog/updated",
                            Query =
                                [
                                    since = Text.From(since) ?? "0"
                                ],
                            Headers =
                                [
                                    Authorization = authorizationToken,
                                    Accept = "application/json"
                                ]
                        ]
                    )
                ),

            worklogGrabber =
                List.Generate(
                    () =>
                        [
                            request = worklog(dateAsTextToUnixMs),
                            next = request[until]?,
                            isLast = request[lastPage]?,
                            index = 0
                        ],
                    (i) =>
                        i[index] = 0 or not i[isLast],
                    (i) =>
                        [
                            request = worklog(next),
                            next = i[request]?[until]?,
                            isLast = i[request]?[lastPage]?,
                            index = i[index] + 1
                        ],
                    (i) =>
                        List.Transform(
                            i[request]?[values]?,
                            each Number.From([worklogId]?)
                        )
                ),

            listResult = List.Combine(worklogGrabber),

            splitToPagesByMaxLimit = List.Split(listResult, maxLimitForWorklogPage),

            postIdsToGetWorklogs = (listOfIds as list) =>
                Json.Document(
                    Web.Contents(
                        jiraHost,
                        [
                            RelativePath = "rest/api/3/worklog/list",
                            Content = Json.FromValue([ids = listOfIds]),
                            Headers =
                                [
                                    Accept = "application/json",
                                    #"Content-Type" = "application/json",
                                    Authorization = authorizationToken
                                ]
                        ]
                    )
                ),

            collectWorklogs = List.Transform(splitToPagesByMaxLimit, each postIdsToGetWorklogs(_)),

            worklogListResult = List.Combine(collectWorklogs),

            worklogsTable =
                #table(
                    type table
                    [
                        id = Int64.Type,
                        issueId = Int64.Type,
                        author_accountId = text,
                        updateAuthor_accountId = text,
                        timeSpent = text,
                        timeSpentSeconds = Int64.Type,
                        created = datetimezone,
                        updated = datetimezone,
                        started = datetimezone
                    ],
                    List.Transform(
                        worklogListResult,
                        each
                            {
                                Number.From([id]?),
                                Number.From([issueId]?),
                                [author]?[accountId]?,
                                [updateAuthor]?[accountId]?,
                                [timeSpent]?,
                                Number.From([timeSpentSeconds]?),
                                DateTimeZone.From([created]?),
                                DateTimeZone.From([updated]?),
                                DateTimeZone.From([started]?)
                            }
                    )
                )
        in
            worklogsTable,

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

            optional fromDateAsText as
                (type nullable text meta
                    [
                        Documentation.FieldCaption = "fromDateAsText",
                        Documentation.FieldDescription = "Optional starting date for updated worklogs, in a format that DateTime.From can parse, for example ""2024-01-01"". Strongly recommended. If omitted or left blank, the function uses Unix timestamp 0 (1970-01-01) and returns worklogs updated from the beginning of time, which can make the request extremely heavy on large Jira instances.",
                        Documentation.SampleValues = { "2024-01-01", "2024-06-01T00:00:00" }
                    ]
                )
        )
        as any meta
        [
            Documentation.Name = "post-jira-worklogs-updated",
            Documentation.Description = "Post Jira worklogs updated since a given date. Internally calls /rest/api/3/worklog/updated to collect worklog IDs and uses POST /rest/api/3/worklog/list to retrieve full worklog details in batches of up to 1000 items. The result is returned as a typed table with fields id, issueId, author_accountId, author_dp, updateAuthor_accountId, timeSpent, timeSpentSeconds, created, updated and started. It is strongly recommended to pass fromDateAsText so you do not scan worklogs from the beginning of time. Note: Provide the jiraHost parameter when calling this function.",
            Documentation.Source = "https://www.vojtechsima.com/",
            Documentation.Version = "1.0",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Load worklogs updated since 1 January 2024 using basic authentication with user and token.",
                        Code = "postWorklogsUpdated(""Basic user:token"", ""2024-01-01"")",
                        Result = "Returns a table of worklogs updated since 1 January 2024, including issueId, author and time tracking fields."
                    ],
                    [
                        Description = "Load all worklogs from the beginning of time (not recommended for large instances).",
                        Code = "postWorklogsUpdated(""Basic user:token"")",
                        Result = "Returns a table of all worklogs the user can see, which may be very large and slow to refresh."
                    ]
                }
        ]
in
    Value.ReplaceType(
        postWorklogsUpdated,
        functionType

    )
