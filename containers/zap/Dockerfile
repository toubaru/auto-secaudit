FROM owasp/zap2docker-stable

# Install zap plugin
RUN zap.sh -cmd -addoninstall ascanrulesAlpha \
    && zap.sh -cmd -addoninstall ascanrulesBeta \
    && zap.sh -cmd -addoninstall sqliplugin \
    && zap.sh -cmd -addonupdate
