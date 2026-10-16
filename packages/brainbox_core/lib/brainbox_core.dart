/// Shared code for the BrAInBox student app and admin portal.
///
/// Import this one file in the apps:
/// ```dart
/// import 'package:brainbox_core/brainbox_core.dart';
/// ```
library;

// Config
export 'config/env.dart';
export 'config/firebase_setup.dart';

// API
export 'api/api_client.dart';
export 'api/api_exception.dart';
export 'api/auth_interceptor.dart';
export 'api/job_poller.dart';

// Auth
export 'auth/current_user_provider.dart';

// Models
export 'models/ai_job.dart';
export 'models/app_user.dart';
export 'models/community_post.dart';
export 'models/concept.dart';
export 'models/mcq_option.dart';
export 'models/mistake.dart';
export 'models/note.dart';
export 'models/question.dart';
export 'models/recommendation.dart';
export 'models/topic.dart';
export 'models/unit.dart';
export 'models/visual.dart';

// Theme
export 'theme/app_colors.dart';
export 'theme/app_spacing.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';

// Widgets
export 'widgets/ai_badge.dart';
export 'widgets/ai_generating_loader.dart';
export 'widgets/app_button.dart';
export 'widgets/app_logo.dart';
export 'widgets/app_text_field.dart';
export 'widgets/empty_state.dart';
export 'widgets/error_banner.dart';
export 'widgets/feature_placeholder.dart';
export 'widgets/firebase_status_banner.dart';
export 'widgets/loading_overlay.dart';
export 'widgets/mastery_ring.dart';
export 'widgets/mcq_option_tile.dart';
export 'widgets/topic_card.dart';

// Utils
export 'utils/firebase_error_mapper.dart';
export 'utils/formatters.dart';
export 'utils/validators.dart';
