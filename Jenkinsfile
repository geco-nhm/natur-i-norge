@Library('jenkins-shared-lib@main') _

flutterPipeline(
    agentLabel: 'mbp-m2p',
    platforms: ['android', 'ios', 'web'],
    test: true,
    analyze: true,
    vault: [
        url: 'https://vault.internal.michaltorma.com',
        path: 'secret/data/mobile/apps/naturinorge_guide/android',
        credentialsId: 'vault-token'
    ]
)
