import { github } from "../client.ts";
import { paginate } from "../utils/paginate.ts";
import type { Repository, Commit, CommitHistoryConnection } from "./__generated__/types";

const COMMITS_PER_PAGE = 100;

export const getCommits = async (
  owner: string,
  repo: string
): Promise<Commit[]> => {
  try {
    return await paginate(async (cursor: string | null) => {
      const response = await github.graphql<{ repository: Repository }>(`
        query GetCommits($owner: String!, $name: String!, $num: Int!, $cursor: String) {
          repository(owner: $owner, name: $name) {
            defaultBranchRef {
              target {
                ... on Commit {
                  history(first: $num, after: $cursor) {
                    pageInfo {
                      hasNextPage
                      endCursor
                    }
                    nodes {
                      oid
                      messageHeadline
                      message
                      committedDate
                      author {
                        name
                        email
                        user {
                          login
                        }
                      }
                      committer {
                        name
                        email
                        user {
                          login
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }`, {
        owner,
        name: repo,
        cursor,
        num: COMMITS_PER_PAGE,
      });



      const targetBranch = response?.repository?.defaultBranchRef?.target;
      const commitHistory = targetBranch && 'history' in targetBranch ? targetBranch.history as CommitHistoryConnection : null;
      const commits = commitHistory?.nodes ?? [];
      const pageInfo = {
        hasNextPage: commitHistory?.pageInfo?.hasNextPage ?? false,
        endCursor: commitHistory?.pageInfo?.endCursor ?? null
      };

      return {
        data: commits.filter(Boolean) as Commit[],
        pageInfo
      };
    });
  } catch (e) {
    console.error(e);
    return [];
  }
};