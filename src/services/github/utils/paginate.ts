import type { PageInfo } from "@octokit/plugin-paginate-graphql/dist-types/page-info";

// Generic paginate function that works with any data structure having PageInfo
export async function paginate<T, P extends PageInfo>(
  fetchPage: (cursor: string | null) => Promise<{ data: T[], pageInfo: P }>
): Promise<T[]> {
  let pageInfo: P | null = {
    hasNextPage: true,
    endCursor: null
  } as P;
  let allData: T[] = [];

  while (pageInfo && 'hasNextPage' in pageInfo && pageInfo.hasNextPage) {
    try {
      const page = await fetchPage(pageInfo?.endCursor);
      allData.push(...page.data);
      pageInfo = {
        hasNextPage: 'hasNextPage' in page.pageInfo ? page.pageInfo.hasNextPage : false,
        endCursor: 'endCursor' in page.pageInfo ? page.pageInfo.endCursor ?? null : null
      } as P;
    } catch (e) {
      console.error(e);
      pageInfo = null;
    }
  }

  return allData;
}
