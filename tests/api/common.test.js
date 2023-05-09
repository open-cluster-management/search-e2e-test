// Copyright Contributors to the Open Cluster Management project

jest.retryTimes(global.retry, { logErrorsBeforeRetry: true })

const squad = require('../../config').get('squadName')
const SEARCH_API_V1 = require('../../config').get('SEARCH_API_V1')
const { getSearchApiRoute, getKubeadminToken } = require('../common-lib/clusterAccess')
const { searchQueryBuilder, sendRequest } = require('../common-lib/searchClient')
const { delayRetry } = require('../common-lib/delayRetry')

const _ = require('lodash')

describe('[P2][Sev2][${squad}] RHACM4K-1696: Search API - Verify search result with common filter and conditions', () => {
  beforeAll(async () => {
    // Log in and get access token
    token = getKubeadminToken()

    // Create a route to access the Search API.
    searchApiRoute = await getSearchApiRoute()
  })

  const app = 'console'
  const namespace = 'openshift-console'

  test(`with query {kind:application name:${app} namespace:${namespace}}`, async () => {
    var query = searchQueryBuilder({
      filters: [
        { property: 'kind', values: ['Deployment'] },
        { property: 'name', values: [app] },
        { property: 'namespace', values: [namespace] },
      ],
    })
    var res = await sendRequest(query, token)
    await delayRetry(() => {
      expect(res.body.data.searchResult[0].items[0].name).toEqual(app)
      expect(res.body.data.searchResult[0].items[0].kind).toMatch(/Deployment/i)
      expect(res.body.data.searchResult[0].items[0].namespace).toEqual(namespace)
    }, 10000)
  }, 15000)

  test(`with query {kind:Pod status:Running namespace:open-cluster-management}`, async () => {
    var query = searchQueryBuilder({
      filters: [
        { property: 'kind', values: ['Pod'] },
        { property: 'namespace', values: ['open-cluster-management'] },
        { property: 'status', values: ['Running'] },
      ],
    })
    var res = await sendRequest(query, token)
    var pods = res.body.data.searchResult[0].items

    pods.forEach((element) => {
      delayRetry(() => {
        expect(element.status).toEqual('Running')
      }, 5000)
    })
  }, 15000)

  test(`with query {kind:Pod cluster:local-cluster status:Running}`, async () => {
    var query = searchQueryBuilder({
      filters: [
        { property: 'kind', values: ['Pod'] },
        { property: 'cluster', values: ['local-cluster'] },
        { property: 'status', values: ['Running'] },
      ],
    })
    var res = await sendRequest(query, token)
    var pods = res.body.data.searchResult[0].items

    pods.forEach((element) => {
      delayRetry(() => {
        expect(element.status).toEqual('Running')
      }, 5000)
    })
  }, 15000)

  test(`with query {kind:ConfigMap namespace:open-cluster-management}`, async () => {
    var query = searchQueryBuilder({
      filters: [
        { property: 'kind', values: ['ConfigMap'] },
        { property: 'namespace', values: ['open-cluster-management'] },
      ],
    })

    var res = await sendRequest(query, token)
    var items = res.body.data.searchResult[0].items

    await delayRetry(() => {
      expect(items[0].kind).toMatch(/ConfigMap/i)
      expect(items.find((el) => el.namespace === 'open-cluster-management')).toBeDefined()
      expect(items.find((el) => el.name.includes('search'))).toBeDefined()
    }, 10000)
  }, 15000)

  test(`with query {kind:Deployment namespace:open-cluster-management}`, async () => {
    var query = searchQueryBuilder({
      filters: [
        { property: 'kind', values: ['Deployment'] },
        { property: 'namespace', values: ['open-cluster-management'] },
      ],
    })

    var res = await sendRequest(query, token)
    var items = res.body.data.searchResult[0].items

    await delayRetry(() => {
      expect(items[0].kind).toMatch(/Deployment/i)
      expect(items.find((deploy) => deploy.namespace === 'open-cluster-management')).toBeDefined()
      expect(items.find((deploy) => deploy.name.includes('search-api'))).toBeDefined()
    }, 10000)
  }, 15000)
})
