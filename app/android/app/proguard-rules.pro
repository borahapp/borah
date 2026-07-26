# RC-04D: regras de ofuscacao/minificacao do release build.
#
# O Flutter Gradle Plugin ja injeta automaticamente as regras necessarias
# para o proprio motor Flutter/Dart (io.flutter.**). As dependencias Android
# nativas usadas pelo projeto (Sentry, PostHog, image_picker, share_plus,
# package_info_plus) publicam suas proprias consumer-rules.pro dentro do
# AAR, aplicadas automaticamente pelo R8 - nao ha necessidade de regras
# adicionais aqui hoje.
#
# Caso um release real (fora deste ambiente, que nao tem SDK Android para
# build completo) revele uma falha por remocao/renomeacao indevida de
# classe, adicionar a regra `-keep` especifica aqui.
