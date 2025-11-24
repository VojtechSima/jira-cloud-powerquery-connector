# jira-cloud-powerquery-connector

Power Query M functions for Jira Cloud work items, boards, sprints, users and worklogs.  
You can use them in Power BI Desktop, Excel or Fabric's Dataflows to build your own Jira reports.

The functions wrap official Jira Cloud REST API endpoints, such as (but not limited to):

- `/rest/api/3/search/jql` for JQL search  
- `/rest/agile/1.0/board` and `/rest/agile/1.0/board/{boardId}/sprint` for Agile data  
- `/rest/api/3/worklog/updated` and `/rest/api/3/worklog/list` for worklogs  

Sources: Atlassian Jira Cloud REST API documentation:
https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/#version

---

## Folder structure

The repository is organised by topic so you can quickly find what you need.

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
