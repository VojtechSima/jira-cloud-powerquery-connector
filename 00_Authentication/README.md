# 00_Authentication

This folder contains helpers for building the HTTP `Authorization` header that all Jira functions in this repository expect.

Right now there is a single function:

- `getBasicAuthorizationToken` builds a `Basic <base64(user:token)>` value for Jira Cloud.

Here, the `user` is your work account or a service account that has access to your desired work items and dimensions.

The `token` is obtained from the Atlassian web UI. Follow the screenshots below.

---

## How to get a Jira Cloud API token

1. Open your Atlassian account in a browser.
2. Navigate to the security section where API tokens are managed.
3. Create a new API token and give it a meaningful label.
4. Copy the generated token.

Screenshots for reference:

<img width="318" height="331" alt="Create token menu" src="https://github.com/user-attachments/assets/f4bd736b-fbbb-4210-be8c-27e68a4408eb" />
<br>
<img width="591" height="54" alt="Security settings" src="https://github.com/user-attachments/assets/914c339d-bfbd-4807-9194-2d8ba8c5a898" />
<br>
<img width="733" height="158" alt="API tokens list" src="https://github.com/user-attachments/assets/d85776a7-285b-4e69-9d1c-b481ccdaa805" />
<br>
<img width="397" height="87" alt="Create new token dialog" src="https://github.com/user-attachments/assets/5d84580f-d5ab-4fb3-b667-ee4874812bf5" />
<br>
<img width="589" height="396" alt="Token created view" src="https://github.com/user-attachments/assets/b837b6c3-ee6e-4c26-97ee-495f3c1c2b2b" />
<br>
<img width="587" height="252" alt="Copy token" src="https://github.com/user-attachments/assets/572d59ab-c6f2-4bdb-b57a-0edeae79145b" />

Make sure you copy the token at this step, because you will not see it again. With this token, you can finish the setup and use the helper function to build the `Authorization` header value.

Since we build our own Authorization header, we also have to set our Data Source credentials to Anonymous (in PBI Desktop, and later in Service), otherwise it won't work.

<img width="699" height="305" alt="image" src="https://github.com/user-attachments/assets/1e1ed14e-3914-42cc-831d-80224f3df971" />
<br>

<img width="402" height="334" alt="image" src="https://github.com/user-attachments/assets/4d7a7e6c-5406-4cef-8c05-6f74476b5771" />

For more stuff about authentication in Power Query and APIs, check out my [blog](https://www.vojtechsima.com/post/api-authentication-in-power-query)


---

## Security note

I do not recommend placing tokens directly into your `.pbix` file.

If you want at least a small extra layer of protection, you can:

- Build the Basic authorization string in a Dataflow (Gen1 or Gen2).
- Then use the Dataflow connection in your report and treat it as a function that returns the token.

That way, the token is not hardcoded in the .pbix file. So if you lose the file, without your work credentials, it should not be accessible.

---

## getBasicAuthorizationToken

**Signature**

```m
getBasicAuthorizationToken(user as text, token as text) as text

---

## `jiraHost` parameter (required)

The queries in this repository expect a Power Query parameter named `jiraHost` to be available at runtime. It must be a Text parameter containing your Jira Cloud host URL in the following format:

- Example value: `https://tenant.atlassian.net`

Why this is required: Power BI Service enforces restrictions around dynamic data sources. Supplying the host as a named Power Query parameter (called `jiraHost`) is inconvenient but necessary so the queries can use the `jiraHost` value without making the Power BI Service treat the source as a dynamic/untrusted source.

How to create the parameter in Power BI Desktop:

1. Open Power BI Desktop and go to `Home` → `Transform data` → `Transform data` to open Power Query Editor.
2. In Power Query Editor, choose `Home` → `Manage Parameters` → `New Parameter`.
3. Configure the parameter:
	- **Name:** `jiraHost`  (this exact name is required)
	- **Description:** Jira Cloud host URL (for example `https://tenant.atlassian.net`)
	- **Type:** `Text`
	- **Suggested Values:** `Any value`
	- **Current Value:** `https://tenant.atlassian.net` (replace with your tenant)
4. Click `OK` to create the parameter. The queries will read `jiraHost` from the parameter at runtime.

Notes:
- Do not rename the parameter: the functions reference `jiraHost` directly in the `Web.Contents(...)` calls.
- This approach is required to avoid Power BI Service dynamic source restrictions when the host would otherwise be injected dynamically at runtime.

