// Copyright (c) 2020 Red Hat, Inc.

const getKubeToken = () => {
  let kubeToken = ''
  try {
    cy.exec(`oc login -u ${Cypress.env('user')} -p ${Cypress.env('password')} --server=https://api.${Cypress.env('baseDomain')}:6443 --insecure-skip-tls-verify=true`)
     .then(() => {
       cy.exec('oc whoami -t').then((res) => {
        process.env.SERVICEACCT_TOKEN = res.stdout
        kubeToken = res.stdout
        console.log('kubeToken', kubeToken)
        return kubeToken
      })
     })
  } catch (e){
    console.error('Error getting kube token. ', e);
    return kubeToken
  }
}

module.exports = getKubeToken;