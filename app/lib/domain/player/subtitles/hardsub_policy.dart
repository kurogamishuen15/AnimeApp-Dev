enum HardsubStatus { confirmedPresent, confirmedAbsent, unknown }

enum ExternalSubtitleDecision { allowed, allowedWithUncertainty, blocked }

/// External subtitles may be attached only when a trusted source has not
/// explicitly confirmed that subtitles are already burned into video frames.
ExternalSubtitleDecision externalSubtitleDecision(HardsubStatus status) =>
    switch (status) {
      HardsubStatus.confirmedPresent => ExternalSubtitleDecision.blocked,
      HardsubStatus.confirmedAbsent => ExternalSubtitleDecision.allowed,
      HardsubStatus.unknown => ExternalSubtitleDecision.allowedWithUncertainty,
    };
