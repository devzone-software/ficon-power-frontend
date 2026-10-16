import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../theme/ficon_theme.dart';

class TuyaSpatialGuidePage extends StatelessWidget {
  const TuyaSpatialGuidePage({
    super.key,
    this.projectQrData = AppConfig.tuyaSpatialProjectQrData,
    this.account = AppConfig.tuyaSpatialAccount,
    this.password = AppConfig.tuyaSpatialPassword,
  });

  final String projectQrData;
  final String account;
  final String password;

  static final Uri downloadUri = Uri.parse(
    'https://images.tuyacn.com/smart/app/package/1283285297/1785838705-tyindustry1.23.0r46_huawei_international.apk',
  );

  static const _deviceSteps = [
    (
      Icons.location_city_outlined,
      'Crear y seleccionar el espacio',
      [
        'Abre el menú «Todos los dispositivos» en la esquina superior izquierda.',
        'En Space List, toca el icono de administración de la esquina superior derecha.',
        'Presiona el botón azul «+» o «+ Add» para crear un espacio.',
        'Escribe el nombre con el formato nombre_ubicación, por ejemplo timax_puno, y toca Guardar.',
        'Comprueba que el espacio quede seleccionado y aparezca en la lista.',
      ],
      'assets/guides/tuya_spatial/create-space.webp',
      'Figura 7. Flujo completo para crear y comprobar un espacio.',
    ),
    (
      Icons.devices_other_outlined,
      'Abrir la lista de dispositivos',
      [
        'Confirma que el nombre del espacio correcto aparezca en la parte superior.',
        'Entra a Devices y toca el botón azul «+» de la esquina superior derecha, marcado con el número 1.',
      ],
      'assets/guides/tuya_spatial/open-add-device.webp',
      'Figura 8. Botón para agregar un dispositivo dentro del espacio seleccionado.',
    ),
    (
      Icons.electric_meter_outlined,
      'Detectar y agregar el medidor',
      [
        'Energiza el WIFI Energy Meter y colócalo en modo de emparejamiento.',
        'Espera mientras Smart Industry busca dispositivos cercanos.',
        'Cuando aparezca el medidor, toca «Agregar», señalado con el número 2.',
      ],
      'assets/guides/tuya_spatial/device-detected.webp',
      'Figura 9. Medidor detectado y acción Agregar.',
    ),
    (
      Icons.wifi,
      'Configurar la red',
      [
        'Toca «Select Wi-Fi», indicador 3, y selecciona la red de la sede.',
        'Escribe la contraseña de esa red en el campo marcado con el indicador 4.',
        'Revisa ambos datos y presiona «Siguiente», indicador 5.',
      ],
      'assets/guides/tuya_spatial/wifi-configuration.webp',
      'Figura 10. Selección de Wi-Fi, contraseña y botón Siguiente.',
    ),
    (
      Icons.bolt,
      'Esperar el emparejamiento',
      [
        'Espera mientras el estado del WIFI Energy Meter indique «Being added».',
        'El indicador 6 muestra el progreso del registro.',
        'No cierres Smart Industry, no cambies de red y no retires la energía del medidor.',
      ],
      'assets/guides/tuya_spatial/pairing-progress.webp',
      'Figura 11. Medidor en proceso de agregado.',
    ),
    (
      Icons.verified_outlined,
      'Confirmar el agregado correcto',
      [
        'Espera el check verde y el texto «Added successfully».',
        'Cuando ya no haya dispositivos agregándose, presiona «Finalizado», indicador 7.',
      ],
      'assets/guides/tuya_spatial/pairing-success.webp',
      'Figura 12. Confirmación del agregado y botón Finalizado.',
    ),
    (
      Icons.fact_check_outlined,
      'Verificar el resultado',
      [
        'Regresa a Devices y confirma que WIFI Energy Meter aparezca dentro del espacio correcto.',
        'Vuelve a FICON y actualiza Dispositivos para comprobar la sincronización.',
        'Si todavía no aparece, revisa la conectividad y solicita al administrador que ejecute nuevamente la sincronización con Tuya.',
      ],
      'assets/guides/tuya_spatial/device-list.webp',
      'Figura 13. WIFI Energy Meter disponible en la lista final.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar un medidor')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FiconColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'El alta se realiza en Smart Industry. FICON registra el medidor '
              'durante la sincronización con Tuya o cuando recibe su primer '
              'evento de conectividad.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          const _RequirementsCard(),
          const SizedBox(height: 10),
          _DownloadStep(onOpen: () => _openDownload(context)),
          _ProjectQrStep(qrData: projectQrData),
          _CredentialsStep(account: account, password: password),
          for (var index = 0; index < _deviceSteps.length; index++)
            _GuideStep(index: index + 4, step: _deviceSteps[index]),
          const SizedBox(height: 8),
          const Text(
            'Si el dispositivo no aparece, comprueba energía, proximidad, Wi-Fi '
            'compatible y permisos del espacio antes de repetir el enlace.',
          ),
        ],
      ),
    );
  }

  Future<void> _openDownload(BuildContext context) async {
    final opened = await launchUrl(
      downloadUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la descarga de Smart Industry.'),
        ),
      );
    }
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard();

  static const _requirements = [
    'Cuenta autorizada para el proyecto y el activo correspondiente.',
    'WIFI Energy Meter energizado y en modo de emparejamiento.',
    'Red Wi-Fi disponible y su contraseña correcta.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FiconColors.logoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FiconColors.cardBorderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Antes de comenzar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final requirement in _requirements)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: FiconColors.logoBlue,
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Text(requirement)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadStep extends StatelessWidget {
  const _DownloadStep({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      index: 1,
      icon: Icons.shop_outlined,
      title: 'Descargar Smart Industry',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descarga e instala Smart Industry 1.23.0 desde el servidor de Tuya. '
            'Si Android lo solicita, permite instalar aplicaciones desde el '
            'navegador. Conserva Tuya Spatial si ya la tienes instalada.',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Descargar APK internacional'),
          ),
        ],
      ),
    );
  }
}

class _ProjectQrStep extends StatelessWidget {
  const _ProjectQrStep({required this.qrData});

  final String qrData;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      index: 2,
      icon: Icons.qr_code_scanner,
      title: 'Escanear el QR del proyecto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Abre Smart Industry, toca SCAN y escanea el QR del proyecto '
            'Timax-Energy-Detector. Este '
            'código vincula la aplicación con el proyecto cloud; si existen '
            'varios tenants, confirma con el administrador que corresponda al '
            'tenant correcto. Puedes mostrarlo en otra pantalla para facilitar '
            'la lectura.',
          ),
          const SizedBox(height: 14),
          if (qrData.isEmpty)
            const _ConfigurationNotice(
              message:
                  'Configura TUYA_SPATIAL_PROJECT_QR_DATA antes de compilar la APK.',
            )
          else
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: qrData,
                  size: 220,
                  backgroundColor: Colors.white,
                  semanticsLabel: 'QR del proyecto Timax-Energy-Detector',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep({required this.account, required this.password});

  final String account;
  final String password;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      index: 3,
      icon: Icons.login,
      title: 'Iniciar sesión',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Después de escanear el QR, ingresa la cuenta y contraseña creadas '
            'por el administrador. El acceso solo mostrará los activos '
            'asignados a ese usuario. La contraseña permanece oculta y solo '
            'puede copiarse.',
          ),
          const SizedBox(height: 12),
          if (account.isEmpty || password.isEmpty)
            const _ConfigurationNotice(
              message:
                  'Configura TUYA_SPATIAL_ACCOUNT y TUYA_SPATIAL_PASSWORD antes de compilar.',
            )
          else ...[
            _CopyValue(label: 'Cuenta', value: account),
            const SizedBox(height: 8),
            _CopyValue(label: 'Contraseña', value: password, obscured: true),
          ],
          const SizedBox(height: 12),
          const _GuideFigure(
            asset: 'assets/guides/tuya_spatial/login.webp',
            caption:
                'Figura 6. Inicio de sesión con una cuenta autorizada del proyecto.',
          ),
        ],
      ),
    );
  }
}

class _CopyValue extends StatelessWidget {
  const _CopyValue({
    required this.label,
    required this.value,
    this.obscured = false,
  });

  final String label;
  final String value;
  final bool obscured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: FiconColors.cardBorderSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FiconColors.cardBorderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  obscured ? '••••••••••••' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FiconColors.ink,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copiar $label',
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copiada al portapapeles.')));
  }
}

class _ConfigurationNotice extends StatelessWidget {
  const _ConfigurationNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FiconColors.logoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.index, required this.step});

  final int index;
  final (IconData, String, List<String>, String, String) step;

  @override
  Widget build(BuildContext context) {
    return _StepCard(
      index: index,
      icon: step.$1,
      title: step.$2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var item = 0; item < step.$3.length; item++) ...[
            if (item > 0) const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item + 1}. ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Expanded(child: Text(step.$3[item])),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _GuideFigure(asset: step.$4, caption: step.$5),
        ],
      ),
    );
  }
}

class _GuideFigure extends StatelessWidget {
  const _GuideFigure({required this.asset, required this.caption});

  final String asset;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final landscape = asset.endsWith('create-space.webp');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showExpanded(context),
          child: Container(
            width: double.infinity,
            height: landscape ? 210 : 350,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FiconColors.cardBorderSoft),
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              semanticLabel: caption,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$caption Toca la imagen para ampliarla.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: FiconColors.slate),
        ),
      ],
    );
  }

  Future<void> _showExpanded(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(child: Image.asset(asset, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar imagen',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.child,
  });

  final int index;
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: FiconColors.logoBlue.withValues(alpha: 0.12),
              child: Icon(icon, color: FiconColors.logoBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. $title',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
