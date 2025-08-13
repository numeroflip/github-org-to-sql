
export const REPOS_PER_PAGE = 100;
const org = process.env.GITHUB_ORG;
if (!org) {
  throw new Error("GITHUB_ORG must be set in the environment.");
}
export const GITHUB_ORG = org;

const envToken = process.env.GITHUB_TOKEN 
if (!envToken) {
  throw new Error("GITHUB_TOKEN must be set in the environment.");
}
export const GITHUB_TOKEN = envToken;