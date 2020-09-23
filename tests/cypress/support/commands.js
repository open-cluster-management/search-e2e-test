/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add("login", (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

import { getOpt } from '../scripts/utils'

import 'cypress-wait-until'
import { searchPage } from '../views/search'

Cypress.Commands.add('login', (OPTIONS_HUB_USER, OPTIONS_HUB_PASSWORD, OC_IDP) => {
  var user = OPTIONS_HUB_USER || Cypress.env('OPTIONS_HUB_USER');
  var password = OPTIONS_HUB_PASSWORD || Cypress.env('OPTIONS_HUB_PASSWORD');
  var idp = OC_IDP || Cypress.env('OC_IDP');
  searchPage.whenGoToSearchPage()
  cy.get('body').then(body => {
    // Check if logged in
    if (body.find('#header').length === 0) {

      // Check if identity providers are configured
      if (body.find('form').length === 0)
        cy.contains(idp).click()
      cy.get('#inputUsername').type(user)
      cy.get('#inputPassword').type(password)
      cy.get('button[type="submit"]').click()
      cy.wait(6000)
      cy.get('#header', {timeout: 30000}).should('exist')
    }
  })
})

Cypress.Commands.add('waitUntilContains', (selector, text, options) => {
  cy.waitUntil(() => cy.ifContains(selector, text, () => true), options);
})

Cypress.Commands.add('waitUntilNotContains', (selector, text, options) => {
  cy.waitUntil(() => cy.ifNotContains(selector, text, () => true), options);
})

Cypress.Commands.add('ifContains', (selector, text, action) => {
  cy.get('body').then($body => {
    var $elem = $body.find(selector)
    if ($elem && $elem.text().includes(text)) {
      return action($elem)
    }
  })
})

Cypress.Commands.add('ifNotContains', (selector, text, action) => {
  cy.get('body').then($body => {
    var $elem = $body.find(selector)
    if (!$elem || !$elem.text().includes(text)) {
      return action($elem)
    }
  })
})

Cypress.Commands.add('forEach', (selector, action, options) => {
  var failIfNotFound = getOpt(options, 'failIfNotFound', false)
  if (failIfNotFound == true) {
    return cy.get(selector, options).each(($elem) => action($elem))
  }

  return cy.get('body').then(($body) => {
    var $elems = $body.find(selector)
    if ($elems.length > 0) {
      action($elems.get(0))
      cy.forEach(selector, action)
    }
  });
})

Cypress.Commands.add('logout', () => {
  cy.get('#acm-user-dropdown').click().then(() => cy.get('#acm-logout').click()).wait(1000)
})

Cypress.Commands.add('generateNamespace', () => {
  return 'search-' + Date.now();
})

Cypress.Commands.add('waitUsingSLA', () => {
  return cy.wait(parseInt(Cypress.env('SERVICE_SLA'), 10) || 5000)
})