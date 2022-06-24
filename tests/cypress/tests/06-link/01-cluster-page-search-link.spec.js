/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2021 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { squad, tags } from '../../config'
import { clustersPage } from '../../views/clusters'

describe.skip('RHACM4K-413: Search: Linked page', { tags: [] }, function () {
  beforeEach(function () {
    // Log into the cluster ACM console.
    cy.visitAndLogin('/multicloud/home/welcome')
  })

  context(
    'verify: cluster page link to search page',
    { tags: [] },
    function () {
      it(`[P1][Sev1][${squad}] should load the cluster page`, function () {
        clustersPage.shouldLoad()
      })

      it(`[P2][Sev2][${squad}] clusters page should have link to search page`, function () {
        clustersPage.shouldHaveLinkToSearchPage()
      })
    }
  )
})
