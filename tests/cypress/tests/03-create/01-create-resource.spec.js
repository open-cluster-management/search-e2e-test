/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { squad, tags } from '../../config'
import { searchPage } from '../../views/search'
import { cliHelper } from '../../scripts/cliHelper'

const clusterModes = [
  { label: 'Local', valueFn: () => cy.wrap('local-cluster'), skip: false },
]

clusterModes.forEach((clusterMode) => {
  if (clusterMode.skip) {
    return
  }

  describe(
    'RHACM4K-1233: Search: Search in ' + clusterMode.label + ' Cluster',
    { tags: [] },
    function () {
      context(
        'prereq: user should log into the ACM console',
        { tags: tags.required },
        function () {
          it(`[P1][Sev1][${squad}] should login`, function () {
            cy.visitAndLogin('/multicloud/home/welcome')
          })
        }
      )

      // For now, we are only clicking the button within the hub cluster header.
      context(
        'search resources: verify create resource in search',
        { tags: [] },
        function () {
          beforeEach(function () {
            cliHelper.checkIfLoggedIn()
            searchPage.whenGoToSearchPage()
          })

          it(`[P2][Sev2][${squad}] should load the search page`, function () {
            searchPage.shouldLoad()
          })

          it(`[P2][Sev2][${squad}] should have link to resource creation page`, function () {
            searchPage.whenCreateResourceObject()
          })
        }
      )
    }
  )
})
