/** *****************************************************************************
 * Licensed Materials - Property of Red Hat, Inc.
 * Copyright (c) 2020 Red Hat, Inc.
 ****************************************************************************** */

/// <reference types="cypress" />

import { popupModal } from '../views/popup'

export const deploymentDetailPage = {
  whenScaleReplicasTo:(replicas) => {
    cy.get('button.pf-m-primary').click({ timeout: 10000, force: true })
    cy.get('.react-monaco-editor-container').click().type(Cypress.platform !== 'darwin' ? '{ctrl}f' : '{meta}f')
      .get('.find-widget .monaco-inputbox textarea:first').focus().click().type('replicas: 1')
    cy.get('.react-monaco-editor-container .view-line > span')
      .filter(':contains("replicas:")').contains('1').parent()
      .find('span:last').click().focused().type('{del}' + replicas)
    cy.get('button.pf-m-primary').filter(':contains("Save")').click({ timeout: 10000, force: true })
    // popupModal.whenAccept() // FIXME: Jorge
  }
}
