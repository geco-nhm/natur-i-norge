@Library('jenkins-shared-lib') _

flutterPipeline(
    agentLabel: 'mbp-m2p',
    platforms: ['android', 'ios'],
    test: true,
    analyze: true,
    vault: [
        url: 'https://vault.internal.michaltorma.com',
        path: 'secret/data/mobile/apps/naturinorge_guide/android',
        credentialsId: 'vault-token'
    ]
)
