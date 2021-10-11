/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { squad, tags } from '../../config'
import { cliHelper } from '../../scripts/cliHelper'
import { searchPage, searchBar } from '../../views/search'

const clusterModes = [
  {
    label: 'Local',
    valueFn: () => cy.wrap('local-cluster'),
    skip: false,
    namespace: cliHelper.generateNamespace(),
  },
  {
    label: 'Managed',
    valueFn: () => cliHelper.getTargetManagedCluster(),
    skip: true,
    namespace: cliHelper.generateNamespace('', `managed-${Date.now()}`),
  },
]

// Prereq test suite. We need to create the resources for both cluster before we log into the UI.
cliHelper.setup(clusterModes)

clusterModes.forEach((clusterMode) => {
  if (clusterMode.skip) {
    return
  }

  describe('RHACKM4K-726: Search: Search in ' + clusterMode.label + ' Cluster', { tags: tags.environments }, function () {
      before(function () {
        clusterMode.valueFn().as('clusterName')
      })

      // Logging into the hub cluster UI.
      if (clusterMode.label !== 'Managed') {
        context('prereq: user should log into the ACM console', { tags: tags.required }, function () {
          it(`[P1][Sev1][${squad}] should login`, function () {
            cy.login()
          })
        })
      }

      context('search resource: verify delete function in search result', { tags: ['@BVT'] },
        function () {
          beforeEach(function () {
            searchPage.whenGoToSearchPage()
            searchBar.whenFilterByNamespace(clusterMode.namespace, true)
            searchBar.whenFilterByCluster(this.clusterName, true)
            searchPage.shouldLoadResults()
          })

          after(function () {
            cliHelper.login(clusterMode.label)
          })

          it(`[P2][Sev2][${squad}] should delete deployment`, function () {
            searchBar.whenFilterByKind('deployment')
            searchPage.whenDeleteResourceDetailItem(
              'deployment',
              clusterMode.namespace + '-deployment'
            )
          })

          it(`[P2][Sev2][${squad}] should validate deployment was deleted`, function () {
            searchBar.whenFilterByKind('deployment', true)
            searchBar.whenFilterByName(
              clusterMode.namespace + '-deployment',
              true
            )
            searchPage.shouldFindNoResults()
          })

          it(`[P2][Sev2][${squad}] should delete namespace`, function () {
            searchPage.whenDeleteNamespace(clusterMode.namespace)
            cy.waitUsingSLA() // WORKAROUND to wait for resource to get indexed. Better solution is to retry instead of a hard wait.
          })

          it(`[P2][Sev2][${squad}] should validate namespace was deleted`, function () {
            searchPage.shouldFindNoResults()
          })
        }
      )
    }
  )
})
