/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { squad } from '../../config'
import { cliHelper } from '../../scripts/cliHelper'
import { searchPage } from '../../views/search'

const clusterModes = [{ label: 'Local', valueFn: () => cy.wrap('local-cluster'), skip: false },
                      { label: 'Managed', valueFn: () => cliHelper.getTargetManagedCluster(), skip: true }];

clusterModes.forEach((clusterMode) => {
  if (clusterMode.skip) {
    return;
  }

  describe('RHACM4K-1233: Search: Search in ' + clusterMode.label + ' Cluster', function() {
    before(function() {
      cy.login()
    })

    beforeEach(function() {
      searchPage.whenGoToSearchPage()
    })

    // For now, we are only clicking the button within the hub cluster header.
    context('search resources: verify create resource in search', () => {
      it(`[P2][Sev2][${squad}] should load the search page`, function() {
        searchPage.shouldLoad()
      });

      it(`[P2][Sev2][${squad}] should have link to resource creation page`, function() {
        searchPage.whenCreateResourceObject()
      });
    })
  })
});
