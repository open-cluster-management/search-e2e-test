// Copyright (c) 2022 Red Hat, Inc.

const { execSync } = require('child_process')
const lodash = require('lodash')

/**
 * Format filters for search queries.
 * @param {string} kind The kind of resource to filter.
 * @param {Object} group The API group to filter the resources against.
 * @param {string} namespace The namespace to filter the resources against.
 * @param {Object} cluster The cluster to filter the resources against.
 * @returns `filter` Formatted array of object filters.
 */
function formatFilters(
  kind,
  group,
  namespace = '--all-namespaces',
  cluster = { type: 'hub', name: 'local-cluster' }
) {
  const filter = []

  // Add namespace filter
  if (namespace !== '--all-namespaces')
    filter.push({ property: 'namespace', values: [namespace] })

  // Add kind filter
  filter.push({ property: 'kind', values: [kind] })

  // Add group filter
  if (group.useAPIGroup && group.name != 'v1')
    filter.push({ property: 'apigroup', values: [group.name] })

  // Add cluster filter
  filter.push({ property: 'cluster', values: [cluster.name] })

  return filter
}

/**
 * Format resources for search queries.
 * @param {Object} cluster The cluster of the resource objects.
 * @param {string} kind The kind of the resource objects.
 * @param {*} resources A list of resources that will be formated as an object containing name and namespace.
 * @returns `formatedResources` Formatted array of resource object.
 */
function formatResources(cluster, kind, resources) {
  var formattedResources = resources.map((res) => {
    const item = res.split(' ').filter((property) => property)
    return {
      cluster: cluster.name,
      kind,
      namespace: item[0],
      name: item[1],
    }
  })

  return formattedResources
}
/**
 * Format resources for search queries.
 * @param {*} resources A list of resources that will be formated as an object containing name and namespace.
 * @returns `formatedResources` Formatted array of resource object.
 */
function formatResourcesFromSearch(resources) {
  var searchResources = lodash
    .get(resources, 'body.data.searchResult[0].items')
    .filter((items) => items.namespace) // We're only interested in resources that have a namespace.
    .map((item) => ({
      cluster: item.cluster,
      kind: item.kind,
      name: item.name,
      namespace: item.namespace,
    }))

  return searchResources
}

/**
 * Fetches all namespaced resources that has methods list and watch.
 ** When fetching the api-resources, the data will be returned with the following format: [0]: NAME, [1]: SHORTNAMES, [2]: APIVERSIONS, [3]: NAMESPACED, [4]: KIND
 ** If there are no short names, the array will be returned with the following format: [0]: NAME, [1]: APIVERSIONS, [2]: NAMESPACED, [3]: KIND
 * @returns `resourceList` List of resource kinds that contains the following methods: (list, watch)
 */
function fetchAPIResourcesWithListWatchMethods() {
  const resourceList = []

  try {
    execSync(
      "oc api-resources --namespaced -o wide --sort-by=kind | grep -E 'list.*watch|watch.*list'"
    )
      .toString()
      .split('\n')
      .filter((resources) => resources)
      .forEach((res) => {
        var obj = { apigroup: '', kind: '' }

        // We need to start off with slicing the string before the methods are listed. (i.e [get, list, watch])
        // After the string is sliced, we need to split the string and filter out any empty data or whitespace.
        const item = res
          .slice(0, res.indexOf('['))
          .split(' ')
          .filter((data) => data)

        if (item) {
          obj.apigroup =
            item.length < 5 ? item[1].split('/')[0] : item[2].split('/')[0]
          obj.kind =
            item.length < 5 ? item[3].toLowerCase() : item[4].toLowerCase()

          resourceList.push(obj)
        }
      })
  } catch (e) {
    console.error(e)
  }

  return resourceList
}

/**
 * Generates and returns a list of cluster environments.
 * @returns clusters List of clusters environemnt.
 */
function getClusterList() {
  const clusters = [{ type: 'hub', name: 'local-cluster', skip: false }]

  // Get managed cluster.
  const managedCluster = getTargetManagedCluster()

  if (managedCluster) {
    // Set the managed cluster name within the environemnt.
    if (
      !process.env.OPTIONS_MANAGED_CLUSTER_NAME ||
      managedCluster != process.env.OPTIONS_MANAGED_CLUSTER_NAME
    )
      process.env.OPTIONS_MANAGED_CLUSTER_NAME = managedCluster

    clusters.push({
      type: 'managed',
      name: managedCluster,
      skip: true,
    })
  }

  return clusters
}

function getMismatchedResources(receivedList, expectedList) {
  if (receivedList.length > expectedList.length) {
    return receivedList.filter((resource) => !expectedList.find((obj) => {
      obj.name === resource.name && obj.namespace === resource.namespace
    }))

  } else {
    return expectedList.filter((resource) => !receivedList.find((obj) => {
      obj.name === resource.name && obj.namespace === resource.namespace
    }))
  }
}

function getResourcesFromOC(
  kind,
  apigroup,
  namespace = '--all-namespaces',
  cluster = { type: 'hub', name: 'local-cluster' }
) {
  var property = kind

  // Check to see if the test needs to include the apigroup name within the query. For kind resources with v1 versions, no apigroup is needed.
  if (apigroup.useAPIGroup && apigroup.name != 'v1')
    property += `.${apigroup.name}`

  var cmd = `oc get ${property.toLowerCase()} ${
    namespace === '--all-namespaces' ? namespace : `-n ${namespace}`
  } --no-headers `

  // Uncomment the following line for debugging purposes.
  // console.debug(cmd)

  var resources = formatResources(
    cluster,
    kind,
    execSync(cmd, { stdio: [] })
      .toString()
      .split('\n')
      .filter((res) => res)
  )

  return resources
}

/**
 * Return an imported cluster attached to the current hub cluster environment.
 * @returns `targetCluster` The imported cluster.
 */
function getTargetManagedCluster() {
  var targetCluster

  try {
    // Fetch imported clusters attached to the hub cluster.
    var managedClusters = execSync(
      'oc get managedclusters -o custom-columns=NAME:.metadata.name --no-headers'
    )
      .toString()
      .split('\n')
      .filter((cluster) => cluster)

    console.info('Found the following clusters:', managedClusters)

    // Check to see if the managed cluster name exist wihin the environment.
    if (process.env.OPTIONS_MANAGED_CLUSTER_NAME) {
      console.info(
        `Checking for the exported managed cluster: ${process.env.OPTIONS_MANAGED_CLUSTER_NAME} within the returned list.`
      )

      if (
        managedClusters.find((c) =>
          c.includes(process.env.OPTIONS_MANAGED_CLUSTER_NAME)
        )
      ) {
        targetCluster = process.env.OPTIONS_MANAGED_CLUSTER_NAME
        return targetCluster
      }

      console.warn(
        `The targeted managed cluster: ${process.env.OPTIONS_MANAGED_CLUSTER_NAME} was not found in the list: ${managedClusters}`
      )
    }

    if (
      managedClusters.length === 1 &&
      managedClusters.find((c) => c.includes('local-cluster'))
    ) {
      console.info(
        `Managed cluster list only contains one managed cluster: ${managedClusters}. Proceeding to test only the local-cluster.`
      )
      return targetCluster
    } else {
      // In the canary tests, we only need to focus on the import-xxxx managed cluster.
      targetCluster = managedClusters.find(
        (c) =>
          c.startsWith('canary-') ||
          c.includes('canary') ||
          c.startsWith('import-')
      )
    }

    if (targetCluster === undefined) {
      targetCluster = managedClusters.find((c) => !c.includes('local-cluster'))
    }

    console.info(`Preparing to test with managed cluster: ${targetCluster}`)
    return targetCluster
  } catch (err) {
    console.warn(
      err,
      'Error getting managedclusters. Proceeding with the local cluster.'
    )
    return
  }
}

/**
 * Filter the array to contain only non-empty values.
 * @param {Array} array The array to filter the values from.
 * @returns `array` The filtered array.
 */
function removeEmptyEntries(array) {
  return array.filter((val) => val.replace(/\s+/g, ' '))
}

/**
 * Determines whether the api resource is required to use the specified api group for its kind.
 * @param {string} kind The api resource kind.
 * @param {Array} resourceList List of api resources.
 * @param {Array} requiredList List of api resources that are required to use their respective api group.
 * @returns `bool` The status of whether the api resource is required for usage.
 */
function shouldUseAPIGroup(kind, resourceList, requiredList = []) {
  const _ = resourceList.filter((res) => res.kind === kind)
  return _.length > 1 || requiredList.includes(kind)
}

/**
 * Determines whether the api resource is required to use the specified api group for its kind.
 * @param {string} kind The api resource kind.
 * @param {Array} resourceList List of api resources.
 * @param {Array} requiredList List of api resources that are required to use their respective api group.
 * @returns `bool` The status of whether the api resource is required for usage.
 */
function verifyMissingResourcesFound(
  missingResourceList,
  resourceList,
  expectedResourceList
) {
  var presentInResourceLists = false

  console.log('verifying missing resources')
  missingResourceList.map((resource) => {
    console.log(resource)
  })

  return
}

exports.fetchAPIResourcesWithListWatchMethods =
  fetchAPIResourcesWithListWatchMethods
exports.formatFilters = formatFilters
exports.formatResources = formatResources
exports.formatResourcesFromSearch = formatResourcesFromSearch
exports.getClusterList = getClusterList
exports.getMismatchedResources = getMismatchedResources
exports.getResourcesFromOC = getResourcesFromOC
exports.getTargetManagedCluster = getTargetManagedCluster
exports.removeEmptyEntries = removeEmptyEntries
exports.shouldUseAPIGroup = shouldUseAPIGroup
exports.verifyMissingResourcesFound = verifyMissingResourcesFound
