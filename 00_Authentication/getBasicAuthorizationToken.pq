let
    getBasicAuthorizationToken =
        (user as text, token as text) =>
        let
            basicAuthorization =
                "Basic "
                & Binary.ToText(
                    Text.ToBinary(user & ":" & token, BinaryEncoding.Base64)
                )
        in
            basicAuthorization,

    functionType =
        type function
        (
            user as
                (type text meta
                    [
                        Documentation.FieldCaption = "user",
                        Documentation.FieldDescription = "Username or email address used for basic authentication.",
                        Documentation.SampleValues = { "user" }
                    ]
                ),

            token as
                (type text meta
                    [
                        Documentation.FieldCaption = "token",
                        Documentation.FieldDescription = "Password or API token paired with the user for basic authentication.",
                        Documentation.SampleValues = { "token" }
                    ]
                )
        )
        as text meta
        [
            Documentation.Name = "get-basic-authorization-token",
            Documentation.Description = "Build an HTTP Basic Authorization header value from user and token in the form ""Basic <base64(user:token)>"".",
            Documentation.Source = "Jira HTTP authentication pattern using Basic user:token",
            Documentation.Version = "1.0",
            Documentation.Author = "Vojtěch Šíma",
            Documentation.Examples =
                {
                    [
                        Description = "Create a Basic header value for the combination user:token.",
                        Code = "getBasicAuthorizationToken(""user"", ""token"")",
                        Result = "Returns a text value that starts with ""Basic "" followed by the Base64 encoded ""user:token"" string."
                    ]
                }
        ]
in
    Value.ReplaceType(
        getBasicAuthorizationToken,
        functionType
    )