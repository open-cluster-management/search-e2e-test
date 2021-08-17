/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { squad } from '../../config'
import { searchPage, searchBar } from '../../views/search'
import {
  filtersRegistry,
  multipleValues,
  combined,
  simple,
  useText,
} from '../../scripts/filters'

// Filter Specification
// - type: the filter name
// - options:
//    - values: the values that the test will type for each filter
//    - strategies: the type of strategy to be performed for each filter
//
// Values Specification
// - useText(val, next): will type the `val` value in th search bar and then will type the `next` value if it exists.
// - useNextSuggestion(): will select the first suggestion
//
// Strategies Specification
// - simple(): it will check that the filter option is available and it shows suggestions
// - combined(list): it will check that the combination of the current filter with the filters provided in the `list` arguments works fine
// - multipleValues(count): it will check that the filter works fine when using multiple values at the same time

const nameFilter = filtersRegistry.createFilter('name')
const labelFilter = filtersRegistry.createFilter('label')
const kindFilter = filtersRegistry.createFilter('kind', {
  strategies: [multipleValues(2), combined([nameFilter, labelFilter])],
})
filtersRegistry.createFilter('role', {
  values: [useText('master'), useText('worker')],
  strategies: [multipleValues(2)],
})
filtersRegistry.createFilter('status', {
  strategies: [simple, multipleValues(2)],
})

describe('RHACM4K-537: Search: Search using filters', function () {
  before(function () {
    cy.login()
    searchPage.whenGoToSearchPage()
  })

  filtersRegistry.filters.forEach((filter) => {
    if (filter.skip) {
      return
    }

    describe(`[P1][Sev1][${squad}] Search using "${filter.type}" filter`, function () {
      beforeEach(function () {
        searchBar.whenClearFilters()
        searchBar.whenFocusSearchBar()
      })

      if (filter.strategies) {
        filter.strategies.forEach((runner) => runner(filter))
      }
    })
  })
})