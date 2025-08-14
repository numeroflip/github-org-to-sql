import type { PageInfo as PageInfoGenerated } from "../resources/__generated__/types";

export type PageInfo = Pick<PageInfoGenerated, "hasNextPage" | "endCursor"> & {
  hasNextPage: boolean;
  endCursor: string | null;
}

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
      const page = await fetchPage(pageInfo?.endCursor ?? null);
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
