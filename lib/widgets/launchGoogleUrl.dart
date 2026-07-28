import 'package:url_launcher/url_launcher.dart';

Future<void> launchGoogleUrl(googleUrl) async {
  final Uri url = Uri.parse(googleUrl);

  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not open the URL.';
  }
}
