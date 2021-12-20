/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2021 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import {tags} from '../../config'
import {searchPage} from '../../views/search'
import {cliHelper} from "../../scripts/cliHelper";
import {clustersPage} from "../../views/clusters";

describe('Search: Test "search-collector" add-on function', {tags: tags.component}, function () {
    before(() => {
        // Get name of an imported cluster
        cliHelper.getTargetManagedCluster().as('managedCluster')
        if (this.managedCluster === 'local-cluster'){
            Cypress.on('fail - No managed cluster found', (error, runnable) => { throw error; });
        }
    })

    it(`RHACM4K-3941: Search function can be disabled on the managed cluster`, {tags: ['@RHACM4K-3941', '@post-release']}, function () {
        /* Verify search-collector can be found on Add-ons page*/
        // Log in yo ACM
        cy.login()
        // Go to 'Add-on' page of a managed cluster and verify 'search-collector' is available
        clustersPage.whenAddonAvailable('true', this.managedCluster, 'search-collector')

        /* Disable search-collector */
        // Flag search-collector to false
        cliHelper.flagSearchCollector('false', this.managedCluster)
        // Go to 'Add-on' page of a managed cluster and verify 'search-collector' is not available
        clustersPage.whenAddonAvailable('false', this.managedCluster, 'search-collector')

        /* Verify Search page */
        // Verify expected warning text exists
        searchPage.whenSearchDisabledOnClusters('true')

        /* Enable search-collector */
        // Flag search-collector to true
        cliHelper.flagSearchCollector('true', this.managedCluster)
        // Go to 'Add-on' page of a managed cluster and verify 'search-collector' is available
        clustersPage.whenAddonAvailable('true', this.managedCluster, 'search-collector')

        /* Verify Search page */
        // Verify warning text does not exists
        searchPage.whenSearchDisabledOnClusters('false')
    })
})


