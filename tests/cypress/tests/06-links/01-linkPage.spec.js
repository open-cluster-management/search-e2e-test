/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2021 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { squad } from '../../config'
import { clustersPage } from '../../views/clusters'

describe('Search: Linked page', function () {
  before(function() {
    cy.login() // Every individual file requires for us to login during the test execution.
  })

  it(`[P2][Sev2][${squad}] clusters page should have link to search page`, function () {
    clustersPage.shouldHaveLinkToSearchPage()
  })
})