/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2021 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { squad } from '../../config'
import { clustersPage } from '../../views/clusters'

describe('RHACM4K-413: Search: Linked page', function () {
  context('prereq: user should log into the ACM console', function () {
    it(`[P1][Sev1][${squad}] should login`, function () {
      cy.login()
    })
  })

  context('verify: cluster page link to search page', function () {
    it(`[P1][Sev1][${squad}] should load the cluster page`, function () {
      clustersPage.shouldLoad()
    })

    it(`[P2][Sev2][${squad}] clusters page should have link to search page`, function () {
      clustersPage.shouldHaveLinkToSearchPage()
    })
  })
})
