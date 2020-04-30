/*******************************************************************************
 * Licensed Materials - Property of IBM
 * (c) Copyright IBM Corporation 2018. All Rights Reserved.
 *
 * Note to U.S. Government Users Restricted Rights:
 * Use, duplication or disclosure restricted by GSA ADP Schedule
 * Contract with IBM Corp.
 *******************************************************************************/
// Copyright (c) 2020 Red Hat, Inc.

const config = require('../../config')

module.exports = {
  url: function () {
    return `${this.api.launchUrl}${config.get('contextPath')}`
  },
  elements: {
    identityProvider: 'a.idp',
    username: '#inputUsername',
    password: '#inputPassword',
    submit: '.btn-lg',
    error: '.bx--inline-notification--error',
    header: '.app-header',
    loginPage: '.login-pf'
  },
  commands: [{
    waitForLoginPageLoad,
    chooseIdentityProvider,
    inputUsername,
    inputPassword,
    submit,
    authenticate,
    waitForLoginSuccess
  }]
}

//helper for other pages to use for authentication in before() their suit
function authenticate(idprovider, username, password) {
  this.waitForLoginPageLoad()
  this.chooseIdentityProvider(idprovider)
  this.inputUsername(username)
  this.inputPassword(password)
  this.submit()
  this.waitForLoginSuccess()
}

function waitForLoginPageLoad() {
  this.waitForElementPresent('@loginPage')
}

function chooseIdentityProvider(idprovider) {
  this.waitForElementPresent('@identityProvider')
  // This will click the id option we created in before setup.
  const userSelector = `a.idp[title="Log in with ${idprovider || 'kube:admin'}"]`
  this.click(userSelector)
}

function inputUsername(username) {
  this.waitForElementVisible('@username')
    .setValue('@username', username || config.get('CLUSTER_ADMIN_USR'))
}

function inputPassword(password) {
  this.waitForElementVisible('@password')
    .setValue('@password', password || config.get('CLUSTER_ADMIN_PWD'))
}

function submit() {
  this.waitForElementVisible('@submit')
    .click('@submit')
}

function waitForLoginSuccess() {
  this.waitForElementVisible('@header', 20000)
}
