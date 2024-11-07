// Copyright Contributors to the Open Cluster Management project

jest.retryTimes(global.retry, { logErrorsBeforeRetry: true })

const squad = require('../../config').get('squadName')
const { getSearchApiRoute, getKubeadminToken } = require('../common-lib/clusterAccess')
const { searchQueryBuilder, sendRequest } = require('../common-lib/searchClient')
const _ = require('lodash')

describe('RHACM4K-1695: Search - verify managed cluster info in the search page', () => {
  beforeAll(async () => {
    // Log in and get access token
    token = getKubeadminToken()

    // Create a route to access the Search API.
    searchApiRoute = await getSearchApiRoute()
  })

  test(`[P1][Sev1][${squad}] Search - verify managed cluster info in the search page.`, async () => {
    var query = searchQueryBuilder({
      filters: [
        { property: 'name', values: ['!local-cluster'] },
        { property: 'ManagedClusterJoined', values: ['True'] },
      ],
    })
    var res = await sendRequest(query, token)
    if (_.get(res, 'body.data.searchResult[0].items[0]', '')) {
      expect(res.body.data.searchResult[0].items[0].ManagedClusterJoined).toEqual('True')

      query = searchQueryBuilder({
        filters: [
          { property: 'cluster', values: ['!local-cluster'] },
          { property: 'kind', values: ['Pod'] },
          { property: 'namespace', values: ['open-cluster-management-agent'] },
        ],
      })
      res = await sendRequest(query, token)

      var pods = _.get(res, 'body.data.searchResult[0].items', [])
      expect(pods.length).toBeGreaterThan(0)
    } else {
      console.log('Test skipped because no managedCluster detected.')
    }
  }, 20000)
})
