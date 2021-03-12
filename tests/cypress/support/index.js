/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

// ***********************************************************
// This example support/index.js is processed and
// loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// You can change the location of this file or turn off
// automatically serving support files with the
// 'supportFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/configuration
// ***********************************************************

import './commands'
require('cypress-terminal-report/src/installLogsCollector')()

process.env.NODE_TLS_REJECT_UNAUTHORIZED='0'
let timeoutID

before(() => {
  cy.clearCookies()
})

beforeEach(() => {
  Cypress.Cookies.preserveOnce('acm-access-token-cookie', '_oauth_proxy', 'XSRF-TOKEN', '_csrf')
  timeoutId = setTimeout(() => {
    throw new Error("Test taking too long!")
  }, 60000 * 5);
})

afterEach(() => {
  clearTimeout(timeoutID)
})
