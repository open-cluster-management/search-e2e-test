/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { searchBar } from "./search";
const typeDelay = 1

export const resourcePage = {
  whenGoToResourcePage: () => cy.get('#acm-create-resource').click(),
  whenSelectTargetCluster: (clusterName) => {
    cy.get('#create-resource-select').click()
    cy.get('.bx--checkbox-wrapper input[name="' + clusterName + '"]').parent().click()
  },
  whenCreateNamespace: (namespace, previouslyCreated=false) => {
    // WORKAROUND: delays are needed because this cypress issue https://github.com/cypress-io/cypress/issues/5480
    cy.get('.react-monaco-editor-container').click().focused().type(Cypress.platform !== 'darwin' ? '{ctrl}a' : '{meta}a')
      .type('{enter}apiVersion: v1{enter}', { delay: typeDelay })
      .type('kind: Namespace{enter}', { delay: typeDelay })
      .type('metadata:{enter}', { delay: typeDelay })
      .type('  name: ' + namespace + '{enter}', { delay: typeDelay });
    resourcePage.shouldCreateResource(previouslyCreated);
  },
  whenCreateDeployment: (namespace, name, image, previouslyCreated=false) => {
    // WORKAROUND: delays are needed because this cypress issue https://github.com/cypress-io/cypress/issues/5480
    cy.get('.react-monaco-editor-container').click().focused().type(Cypress.platform !== 'darwin' ? '{ctrl}a' : '{meta}a')
      .type('{enter}apiVersion: apps/v1{enter}', { delay: typeDelay })
      .type('kind: Deployment{enter}', { delay: typeDelay })
      .type('metadata:{enter}', { delay: typeDelay })
      .type('  name: ' + name + '{enter}{backspace}', { delay: typeDelay })
      .type('  namespace: ' + namespace + '{enter}{backspace}', { delay: typeDelay })
      .type('spec:{enter}', { delay: typeDelay })
      .type('  replicas: 1{enter}{backspace}', { delay: typeDelay })
      .type('  selector:{enter}{backspace}', { delay: typeDelay })
      .type('    matchLabels:{enter}{backspace}{backspace}', { delay: typeDelay })
      .type('      app: ' + name + '{enter}{backspace}{backspace}{backspace}', { delay: typeDelay })
      .type('  template:{enter}{backspace}', { delay: typeDelay })
      .type('    metadata:{enter}{backspace}{backspace}', { delay: typeDelay })
      .type('      labels:{enter}{backspace}{backspace}{backspace}', { delay: typeDelay })
      .type('        app: ' + name + '{enter}{backspace}{backspace}{backspace}{backspace}', { delay: typeDelay })
      .type('    spec:{enter}{backspace}{backspace}', { delay: typeDelay })
      .type('      containers:{enter}{backspace}{backspace}{backspace}', { delay: typeDelay })
      .type('        - name: ' + name + '{enter}{backspace}{backspace}{backspace}{backspace}', { delay: typeDelay })
      .type('          image: ' + image + '{enter}', { delay: typeDelay });
      resourcePage.shouldCreateResource(previouslyCreated);
  },
  shouldCreateResource: (previouslyCreated) => {
    cy.get('.bx--btn--primary', {timeout: 30000}).click();

    if (previouslyCreated) { // Test both scenarios if resource already exist or not.
      cy.get('.bx--inline-notification__subtitle').contains('already exist')
    } else {
      cy.get('.bx--inline-notification__subtitle').should('not.exist')
      cy.get('.bx--inline-notification', { timeout: 30000 }).should('not.exist');
      cy.get('.react-monaco-editor-container', { timeout: 30000 }).should('not.exist')
    }
  },
}
