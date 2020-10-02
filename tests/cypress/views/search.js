/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { popupModal } from '../views/popup'
import { getOpt } from '../scripts/utils'

const SEARCH_MESSAGES_LOADING = 'Loading results'
const SEARCH_MESSAGES_NO_RESULTS = 'No search results found'
const SEARCH_MESSAGES_FEW_SECONDS_AGO = 'a few seconds ago'

export const pageLoader = {
  shouldExist: () => cy.get('.content-spinner', { timeout: 20000 }).should('exist')  ,
  shouldNotExist: () => cy.get('.content-spinner', { timeout: 20000 }).should('not.exist')
}

export const searchPage = {
  whenGoToWelcomePage:() => cy.visit('/multicloud/welcome'), // WORKAROUND for https://github.com/open-cluster-management/backlog/issues/5725
  whenGoToSearchPage:() => cy.visit('/multicloud/search'),
  whenExpandQuickFilters:() => {
    cy.get('.show-more-results-button > button', { timeout: 20000 }).focus().click()
  },
  whenGetResourceDetailItem:(resource, name) => {
    return cy.contains('.search--resource-table-header-button', resource, {timeout: 6000})
             .parentsUntil('.search--resource-table', {timeout: 20000})
             .find('table.bx--data-table-v2 tbody tr', {timeout: 20000}).contains('td', name)
             .parent();
  },
  whenDeleteResourceDetailItem:(resource, name, options) => {
    var force = true
    searchPage.whenGetResourceDetailItem(resource, name).find('td .bx--overflow-menu__icon', {timeout: 2000}).click({ force: true })
    cy.get('.bx--overflow-menu-options button[data-table-action="table.actions.remove"]', {timeout: 2000}).click({ force: true }).wait(1000)
    popupModal.whenAccept()
  },
  whenGoToResourceDetailItemPage: (resource, name) => {
    searchPage.whenGetResourceDetailItem(resource, name).find('td').eq(0).find('a').click()
  },
  whenDeleteNamespace: (namespace, options) => {
    var ignoreIfDoesNotExist = getOpt(options, 'ignoreIfDoesNotExist', true)
    var deleteFn = () => searchPage.whenDeleteResourceDetailItem('namespace', namespace)

    searchPage.whenGoToSearchPage()
    searchBar.whenFilterByKind('namespace')
    searchBar.whenFilterByName(namespace)
    searchPage.shouldLoadResults()
    if (ignoreIfDoesNotExist == true) {
      cy.ifNotContains('.page-content-container', SEARCH_MESSAGES_NO_RESULTS, deleteFn)
    } else {
      deleteFn()
    }
  },
  whenWaitUntilFindResults:(options) => {
    cy.reloadUntil(() => {
      searchPage.shouldLoadResults()
      return cy.ifNotContains('.page-content-container', SEARCH_MESSAGES_NO_RESULTS)
    }, options)
  },
  shouldLoadResults:() => cy.waitUntilNotContains('.search--results-view > h4', SEARCH_MESSAGES_LOADING, { timeout: 60000, interval: 1000 }),
  shouldExist:() => {
    cy.get('.bx--detail-page-header-title', {timeout: 20000}).should('exist')
    cy.get('.react-tags__search-input input', {timeout: 20000}).should('exist')
    cy.get('.saved-search-query-header', { timeout: 20000}).should('exist')
  },
  shouldFindNoResults: (options) => {
    cy.reloadUntil(() => {
      searchPage.shouldLoadResults()
      return cy.ifContains('.page-content-container', SEARCH_MESSAGES_NO_RESULTS)
    }, options)
  },
  shouldFindQuickFilter: (resource, count) => {
    cy.reloadUntil(() => {
      searchPage.shouldLoadResults()
      return cy.ifContains('[for="related-resource-' + resource + '"] > .bx--tile-content', count)
    })
  },
  shouldFindResourceDetailItem: (resource, name) => {
    searchPage.whenGetResourceDetailItem(resource, name).should('exist')
  },
  shouldBeResourceDetailItemCreatedFewSecondsAgo: (resource, name) => {
    searchPage.whenGetResourceDetailItem(resource, name).parent().contains('td', SEARCH_MESSAGES_FEW_SECONDS_AGO)
  }
}

export const searchBar = {
  whenFocusSearchBar:() => {
    cy.get('.react-tags', {timeout: 20000}).click()
  },
  whenClearFilters:() => {
    cy.forEach('.react-tags__selected button', ($elem) => $elem.click(), { failIfNotFound: false })
  },
  whenEnterTextInSearchBar:(property, value) => {
    cy.get('.react-tags__search-input input', {timeout: 20000}).should('exist').focus().click().type(property).wait(200)
    cy.get('.react-tags', {timeout: 20000}).should('exist')
    cy.get('.react-tags__search-input', {timeout: 20000}).should('exist')
    cy.get('.react-tags__search-input input', {timeout: 20000}).type(' ')
    if (value !== null) {
      cy.get('.react-tags__search-input input', {timeout: 20000}).type(value)
      cy.get('.react-tags__search-input input', {timeout: 20000}).type(' ').wait(200)
    }
  },
  whenFilterByCluster:(cluster) => {
    searchBar.whenEnterTextInSearchBar('cluster', cluster)
  },
  whenFilterByClusterAndNamespace:(cluster, namespace) => {
    searchBar.whenFilterByCluster(cluster)
    searchBar.whenEnterTextInSearchBar('namespace', namespace)
  },
  whenFilterByKind:(kind) => {
    searchBar.whenEnterTextInSearchBar('kind', kind)
  },
  whenFilterByName:(name) => {
    searchBar.whenEnterTextInSearchBar('name', name)
  }
}
