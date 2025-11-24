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

All functions also require a `jiraHost` parameter, which is the base url of your Jira tenant in the format:
```text
https://tenant.atlassian.net
```
It is recommended to save this value as a parameter in your Power Query project.

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
