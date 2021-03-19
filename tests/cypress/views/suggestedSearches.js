/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2021 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

export const searchBar = {
  shouldContainTag: (filter) => {
    cy.get('.react-tags__selected-tag-name').should('contain', filter)
  },
}

export const savedSearches = {
  whenSelectCardWithTitle: (title) => {
    cy.get('.pf-c-card__title').contains(title).click()
  },
  whenRelatedItemsExist:()  => {
    cy.get('.pf-l-gallery', {timeout: 20000}).get('.pf-c-skeleton', {timeout: 20000}).should('not.exist')
    cy.get('.pf-l-gallery', {timeout: 20000}).children().should('exist').and('have.length.above', 1)
  },
  whenGetRelatedItemDetails:(resource) => {
    return cy.contains('.search--resource-table', resource, {timeout: 20000})
      .find('table.bx--data-table-v2 tbody tr', {timeout: 20000})
      .parent();
  },
  whenVerifyRelatedItemsDetails:() => {
    cy.waitUsingSLA()
    cy.get('.page-content-container > :nth-child(2)').then(($span) => {
      if (($span.text()) !== 'No search results found.') {
        cy.contains('Show all').click()
        cy.get('.bx--tile-content > :nth-child(1) > .content > .text').each(($el) => {
          const itemName = $el.text()
          cy.wrap($el).click()
        suggestedTemplate.whenGetRelatedItemDetails(itemName).should('exist', {timeout: 20000} )
        cy.wrap($el).click()
        })
      }
    })
  }
}
