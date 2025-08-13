import 'dotenv/config';
import type { CodegenConfig } from '@graphql-codegen/cli';

const token = process.env.GITHUB_TOKEN ?? process.env.GH_TOKEN ?? '';
if (!token) {
	throw new Error('GITHUB_TOKEN or GH_TOKEN must be set for GraphQL Codegen to fetch the GitHub schema.');
}

const config: CodegenConfig = {
	schema: [
		{
			'https://api.github.com/graphql': {
				headers: {
					Authorization: `Bearer ${token}`,
					'User-Agent': 'github-org-to-sql',
				},
			},
		},
	],
	documents: 'src/services/github/resources/**/*.graphql',
	generates: {
		'src/services/github/resources/__generated__/types.ts': {
			plugins: ['typescript', 'typescript-operations'],
			config: {
				useTypeImports: true,
				defaultScalarType: 'unknown',
				scalars: {
					ID: 'string',
					DateTime: 'string',
					URI: 'string',
					URL: 'string',
					HTML: 'string',
					Base64String: 'string',
					GitObjectID: 'string',
					GitTimestamp: 'string',
					GitRefname: 'string',
					GitSSHRemote: 'string',
					PreciseDateTime: 'string',
					X509Certificate: 'string',
					BigInt: 'string'
				}
			}
		}
	},
	overwrite: true
};

export default config;