# Licencias y créditos

## Código de la aplicación

El código propio de Diario Emocional se distribuye bajo la **licencia MIT**.
El texto completo está en [`LICENSE`](../LICENSE).

Copyright (c) 2026 Departamento de Psicología.

Puedes usar, copiar, modificar y redistribuir el código, también con fines
comerciales, siempre que conserves el aviso de copyright y la licencia. El
software se entrega **sin garantía**.

## Tipografía

| Recurso | Licencia | Archivo |
| --- | --- | --- |
| Noto Sans Regular y Bold | SIL Open Font License 1.1 (OFL-1.1) | [`assets/fonts/OFL.txt`](../assets/fonts/OFL.txt) |

Noto Sans se incluye únicamente para que los informes PDF rendericen acentos,
eñes y otros caracteres Unicode sin depender de fuentes del sistema. La OFL
permite incrustar la fuente en documentos y redistribuirla con la app siempre
que se conserve la licencia y no se venda la fuente por separado.

## Dependencias de Dart y Flutter

Las versiones exactas están fijadas en `pubspec.lock`. Todas las licencias son
compatibles con una aplicación open source.

| Paquete | Versión | Licencia | Uso |
| --- | --- | --- | --- |
| `flutter` / `flutter_localizations` | SDK | BSD-3-Clause | Framework y localización |
| `flutter_riverpod` / `riverpod` | 3.5.0 | MIT | Gestión de estado |
| `intl` | 0.20.3 | BSD-3-Clause | Fechas y formatos en español |
| `shared_preferences` | 2.5.6 | BSD-3-Clause | Persistencia local |
| `uuid` | 4.6.0 | MIT | Identificadores locales |
| `firebase_core` | 5.1.0 | BSD-3-Clause | Inicialización de Firebase |
| `firebase_auth` | 7.0.1 | BSD-3-Clause | Acceso con correo y contraseña |
| `cloud_firestore` | 7.1.0 | BSD-3-Clause | Base de datos en la nube |
| `pdf` | 3.13.1 | Apache-2.0 | Generación de documentos PDF |
| `printing` | 5.15.1 | Apache-2.0 | Vista previa e impresión/compartición |
| `file_saver` | 0.7.0 | MIT | Guardado del PDF en el dispositivo |
| `speech_to_text` | 7.5.0 | MIT | Dictado por voz opcional |
| `cupertino_icons` | 1.0.9 | MIT | Iconografía |
| `flutter_lints` | 6.0.0 | BSD-3-Clause | Reglas de análisis (solo desarrollo) |

### Dependencias transitivas

`pubspec.lock` incluye dependencias transitivas de estos paquetes (por ejemplo
`path_provider`, `http`, `archive`, `image`, `xml`, `petitparser` o los
paquetes de plataforma de Firebase). Cada una conserva su propia licencia,
habitualmente BSD, MIT o Apache-2.0. Para consultar el texto exacto de una
dependencia:

```bash
flutter pub deps
# Los LICENSE están en la caché de pub, normalmente:
# %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\<paquete>-<versión>\LICENSE
```

## Servicios de terceros

- **Firebase** (Authentication y Cloud Firestore) es un servicio de Google
  sujeto a sus propios términos y a su política de privacidad. La app no
  incluye credenciales ni un proyecto desplegado; el responsable del
  tratamiento debe contratarlo y configurarlo.
- **Google Fonts / Noto Sans** es un proyecto de Google con licencia OFL.
- **Servicio de voz del sistema** (Google en Android, Apple en iOS): el dictado
  lo utiliza solo cuando la persona pulsa el micrófono. El audio se procesa
  según los términos y la política de privacidad del proveedor del dispositivo.
  La app no guarda grabaciones ni las envía a Firebase.

## Marcas

Los nombres de terceros se usan solo con fines descriptivos. Este proyecto no
está afiliado a Google, Firebase ni a los autores de las dependencias.

## Cómo cumplir las licencias al distribuir

1. Conserva `LICENSE` y `assets/fonts/OFL.txt` en el repositorio y en el
   paquete de distribución.
2. No elimines los avisos de copyright del código de terceros.
3. Si modificas Noto Sans, no uses el nombre reservado "Noto" para la versión
   modificada, tal y como exige la OFL.
4. Si publicas en una tienda, incluye esta página o un enlace a ella en la
   ficha de la aplicación.
