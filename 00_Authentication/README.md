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
