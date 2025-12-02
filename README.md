# jira-cloud-powerquery-connector

Power Query M functions for Jira Cloud work items, boards, sprints, users and worklogs.  
You can use them in Power BI Desktop, Excel or Fabric's Dataflows to build your own Jira reports.

The functions wrap official Jira Cloud REST API endpoints, such as (but not limited to):

- `/rest/api/3/search/jql` for JQL search  
- `/rest/agile/1.0/board` and `/rest/agile/1.0/board/{boardId}/sprint` for Agile data  
- `/rest/api/3/worklog/updated` and `/rest/api/3/worklog/list` for worklogs  

Sources: Atlassian Jira Cloud REST API documentation:  
https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/#version

All functions (except `getBasicAuthorizationToken.pq`, duh) use an `authorizationToken` parameter for authentication.  
You can find a short tutorial on how to obtain this token in `src/00_Authentication`.

## `jiraHost` parameter (required)

The queries in this repository expect a Power Query parameter named `jiraHost` to be available at runtime. It must be a **Text** parameter containing your Jira Cloud host URL in the following format:

- Example value: `https://tenant.atlassian.net`

This pattern is important for Power BI Service because it helps avoid dynamic data source restrictions. The service does not allow scheduled refresh when the root URL is built dynamically at runtime. Microsoft documents dynamic data sources as unsupported for refresh.

By supplying the host as a named parameter, you keep the base URL stable and can still vary paths and query parameters inside `Web.Contents(...)` in a refresh-friendly way.

### How to create the parameter in Power BI Desktop

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

- Do not rename the parameter. The functions reference `jiraHost` directly in `Web.Contents(...)` calls.
- Supplying the host this way is a common workaround to keep Power BI Service refresh working when you use REST APIs and want to avoid dynamic source refresh errors.

---
## Notes

If a function expects a date, it is recommended to use the `YYYY-MM-DD` format when possible.

Every function has documentation for each parameter and field, plus simple usage examples. You can see these in the Power Query user interface before you invoke the function.

Example:  
<br>
<img width="400" height="400" alt="image" src="https://github.com/user-attachments/assets/023eb0ac-53e1-4d6e-9ee2-ed00603d33a6" />

---

## Folder structure

The repository is organized by topic so you can quickly find what you need.

```text
src
├─00_Authentication
│     getBasicAuthorizationToken.pq
│     README.md
│
├─01_JqlSearch
│     getJqlSearch.pq
│     getJqlSearchWithChangelog.pq
│     postJqlSearch.pq
│     postJqlSearchWithChangelog.pq
│
├─02_Dimensions
│     getJiraProjects.pq
│     getJiraUsers.pq
│     getJiraStatuses.pq
│     getJiraResolutions.pq
│     getWorkItemTypes.pq
│
├─03_Agile
│     getJiraBoards.pq
│     getJiraSprints.pq
│
└─04_Worklogs
      postWorklogsUpdated.pq
```
