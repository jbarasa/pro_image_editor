import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/designs/whatsapp/whatsapp_painting_appbar.dart';
import 'package:pro_image_editor/designs/whatsapp/whatsapp_painting_bottombar.dart';
import 'package:pro_image_editor/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/models/theme/theme.dart';
import 'package:pro_image_editor/widgets/layer_stack.dart';

import '../../models/crop_rotate_editor/transform_factors.dart';
import '../../models/editor_configs/paint_editor_configs.dart';
import '../../models/editor_image.dart';
import '../../models/filter_state_history.dart';
import '../../models/blur_state_history.dart';
import '../../models/paint_editor/paint_bottom_bar_item.dart';
import '../../models/layer.dart';
import '../../utils/design_mode.dart';
import '../../utils/helper/editor_mixin.dart';
import '../../utils/theme_functions.dart';
import '../../widgets/color_picker/bar_color_picker.dart';
import '../../widgets/color_picker/color_picker_configs.dart';
import '../../widgets/flat_icon_text_button.dart';
import '../../widgets/platform_popup_menu.dart';
import '../../widgets/pro_image_editor_desktop_mode.dart';
import '../../widgets/transformed_content_generator.dart';
import '../filter_editor/widgets/image_with_multiple_filters.dart';
import 'painting_canvas.dart';
import 'utils/paint_editor_enum.dart';

/// A StatefulWidget that represents an image editor with painting capabilities.
class PaintingEditor extends StatefulWidget with ImageEditorMixin {
  @override
  final ProImageEditorConfigs configs;

  /// The theme configuration for the editor.
  final ThemeData theme;

  /// A Uint8List representing the image data in memory.
  final Uint8List? byteArray;

  /// The asset path of the image.
  final String? assetPath;

  /// The network URL of the image.
  final String? networkUrl;

  /// A File representing the image file.
  final File? file;

  /// The transform configurations how the image should be initialized.
  final TransformConfigs? transformConfigs;

  /// A list of Layer objects representing image layers.
  final List<Layer>? layers;

  /// The size of the image.
  final Size imageSize;

  /// Additional padding for the editor.
  final EdgeInsets? paddingHelper;

  /// A callback function that can be used to update the UI from custom widgets.
  final Function? onUpdateUI;

  /// A list of applied filters to the editor.
  final List<FilterStateHistory> filters;

  /// The blur state to the editor.
  final BlurStateHistory blur;

  /// Constructs a PaintingEditor instance.
  ///
  /// The `PaintingEditor._` constructor should not be directly used. Instead, use one of the factory constructors.
  const PaintingEditor._({
    super.key,
    this.byteArray,
    this.assetPath,
    this.networkUrl,
    this.file,
    required this.theme,
    this.configs = const ProImageEditorConfigs(),
    this.transformConfigs,
    required this.imageSize,
    this.layers,
    this.onUpdateUI,
    this.paddingHelper,
    required this.filters,
    required this.blur,
  }) : assert(
          byteArray != null ||
              file != null ||
              networkUrl != null ||
              assetPath != null,
          'At least one of bytes, file, networkUrl, or assetPath must not be null.',
        );

  ///Constructor for loading image from memory.
  factory PaintingEditor.memory(
    Uint8List byteArray, {
    Key? key,
    required ThemeData theme,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
    TransformConfigs? transformConfigs,
    required Size imageSize,
    List<Layer>? layers,
    EdgeInsets? paddingHelper,
    Function? onUpdateUI,
    List<FilterStateHistory>? filters,
    BlurStateHistory? blur,
  }) {
    return PaintingEditor._(
      key: key,
      byteArray: byteArray,
      onUpdateUI: onUpdateUI,
      theme: theme,
      imageSize: imageSize,
      layers: layers,
      paddingHelper: paddingHelper,
      configs: configs,
      transformConfigs: transformConfigs,
      filters: filters ?? [],
      blur: blur ?? BlurStateHistory(),
    );
  }

  /// Constructor for loading image from [File].
  factory PaintingEditor.file(
    File file, {
    Key? key,
    required ThemeData theme,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
    TransformConfigs? transformConfigs,
    required Size imageSize,
    List<Layer>? layers,
    EdgeInsets? paddingHelper,
    Function? onUpdateUI,
    List<FilterStateHistory>? filters,
    BlurStateHistory? blur,
  }) {
    return PaintingEditor._(
      key: key,
      file: file,
      theme: theme,
      imageSize: imageSize,
      layers: layers,
      paddingHelper: paddingHelper,
      configs: configs,
      transformConfigs: transformConfigs,
      onUpdateUI: onUpdateUI,
      filters: filters ?? [],
      blur: blur ?? BlurStateHistory(),
    );
  }

  /// Constructor for loading image from assetPath.
  factory PaintingEditor.asset(
    String assetPath, {
    Key? key,
    required ThemeData theme,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
    TransformConfigs? transformConfigs,
    required Size imageSize,
    List<Layer>? layers,
    EdgeInsets? paddingHelper,
    Function? onUpdateUI,
    List<FilterStateHistory>? filters,
    BlurStateHistory? blur,
  }) {
    return PaintingEditor._(
      key: key,
      assetPath: assetPath,
      theme: theme,
      imageSize: imageSize,
      layers: layers,
      paddingHelper: paddingHelper,
      configs: configs,
      transformConfigs: transformConfigs,
      onUpdateUI: onUpdateUI,
      filters: filters ?? [],
      blur: blur ?? BlurStateHistory(),
    );
  }

  /// Constructor for loading image from network url.
  factory PaintingEditor.network(
    String networkUrl, {
    Key? key,
    required ThemeData theme,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
    TransformConfigs? transformConfigs,
    required Size imageSize,
    List<Layer>? layers,
    EdgeInsets? paddingHelper,
    Function? onUpdateUI,
    List<FilterStateHistory>? filters,
    BlurStateHistory? blur,
  }) {
    return PaintingEditor._(
      key: key,
      networkUrl: networkUrl,
      theme: theme,
      imageSize: imageSize,
      layers: layers,
      paddingHelper: paddingHelper,
      configs: configs,
      transformConfigs: transformConfigs,
      onUpdateUI: onUpdateUI,
      filters: filters ?? [],
      blur: blur ?? BlurStateHistory(),
    );
  }

  /// Constructor for automatic source selection based on properties
  factory PaintingEditor.autoSource({
    Key? key,
    required ThemeData theme,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
    TransformConfigs? transformConfigs,
    required Size imageSize,
    Uint8List? byteArray,
    File? file,
    String? assetPath,
    String? networkUrl,
    List<Layer>? layers,
    EdgeInsets? paddingHelper,
    Function? onUpdateUI,
    List<FilterStateHistory>? filters,
    BlurStateHistory? blur,
  }) {
    if (byteArray != null) {
      return PaintingEditor.memory(
        byteArray,
        key: key,
        theme: theme,
        imageSize: imageSize,
        layers: layers,
        paddingHelper: paddingHelper,
        configs: configs,
        transformConfigs: transformConfigs,
        onUpdateUI: onUpdateUI,
        filters: filters,
        blur: blur,
      );
    } else if (file != null) {
      return PaintingEditor.file(
        file,
        key: key,
        theme: theme,
        imageSize: imageSize,
        layers: layers,
        paddingHelper: paddingHelper,
        configs: configs,
        transformConfigs: transformConfigs,
        onUpdateUI: onUpdateUI,
        filters: filters,
        blur: blur,
      );
    } else if (networkUrl != null) {
      return PaintingEditor.network(
        networkUrl,
        key: key,
        theme: theme,
        imageSize: imageSize,
        layers: layers,
        paddingHelper: paddingHelper,
        configs: configs,
        transformConfigs: transformConfigs,
        onUpdateUI: onUpdateUI,
        filters: filters,
        blur: blur,
      );
    } else if (assetPath != null) {
      return PaintingEditor.asset(
        assetPath,
        key: key,
        theme: theme,
        imageSize: imageSize,
        layers: layers,
        paddingHelper: paddingHelper,
        configs: configs,
        transformConfigs: transformConfigs,
        onUpdateUI: onUpdateUI,
        filters: filters,
        blur: blur,
      );
    } else {
      throw ArgumentError(
          "Either 'byteArray', 'file', 'networkUrl' or 'assetPath' must be provided.");
    }
  }

  @override
  State<PaintingEditor> createState() => PaintingEditorState();
}

class PaintingEditorState extends State<PaintingEditor>
    with ImageEditorStateMixin {
  /// A global key for accessing the state of the PaintingCanvas widget.
  final _imageKey = GlobalKey<PaintingCanvasState>();

  /// A global key for accessing the state of the Scaffold widget.
  final _key = GlobalKey<ScaffoldState>();

  /// An instance of the EditorImage class representing the image to be edited.
  late EditorImage _editorImage;

  /// A ScrollController for controlling the scrolling behavior of the bottom navigation bar.
  late ScrollController _bottomBarScrollCtrl;

  /// A boolean flag representing whether the fill mode is enabled or disabled.
  bool _fill = false;

  /// Get the fillBackground status.
  bool get fillBackground => _fill;

  /// Determines whether undo actions can be performed on the current state.
  bool get canUndo => _imageKey.currentState?.canUndo == true;

  /// Determines whether redo actions can be performed on the current state.
  bool get canRedo => _imageKey.currentState?.canRedo == true;

  /// Get the current PaintMode from the ImageKey's currentState.
  PaintModeE? get paintMode => _imageKey.currentState?.mode;

  /// Get the current PaintMode.
  PaintModeE? get mode => _imageKey.currentState?.mode;

  /// Get the active selected color.
  Color get activeColor =>
      _imageKey.currentState?.activeColor ?? Colors.black38;

  /// A list of [PaintModeBottomBarItem] representing the available drawing modes in the painting editor.
  /// The list is dynamically generated based on the configuration settings in the [PaintEditorConfigs] object.
  List<PaintModeBottomBarItem> get paintModes => [
        if (paintEditorConfigs.hasOptionFreeStyle)
          PaintModeBottomBarItem(
            mode: PaintModeE.freeStyle,
            icon: icons.paintingEditor.freeStyle,
            label: i18n.paintEditor.freestyle,
          ),
        if (paintEditorConfigs.hasOptionArrow)
          PaintModeBottomBarItem(
            mode: PaintModeE.arrow,
            icon: icons.paintingEditor.arrow,
            label: i18n.paintEditor.arrow,
          ),
        if (paintEditorConfigs.hasOptionLine)
          PaintModeBottomBarItem(
            mode: PaintModeE.line,
            icon: icons.paintingEditor.line,
            label: i18n.paintEditor.line,
          ),
        if (paintEditorConfigs.hasOptionRect)
          PaintModeBottomBarItem(
            mode: PaintModeE.rect,
            icon: icons.paintingEditor.rectangle,
            label: i18n.paintEditor.rectangle,
          ),
        if (paintEditorConfigs.hasOptionCircle)
          PaintModeBottomBarItem(
            mode: PaintModeE.circle,
            icon: icons.paintingEditor.circle,
            label: i18n.paintEditor.circle,
          ),
        if (paintEditorConfigs.hasOptionDashLine)
          PaintModeBottomBarItem(
            mode: PaintModeE.dashLine,
            icon: icons.paintingEditor.dashLine,
            label: i18n.paintEditor.dashLine,
          ),
      ];

  @override
  void initState() {
    _fill = paintEditorConfigs.initialFill;
    _bottomBarScrollCtrl = ScrollController();

    _editorImage = EditorImage(
      assetPath: widget.assetPath,
      byteArray: widget.byteArray,
      file: widget.file,
      networkUrl: widget.networkUrl,
    );

    /// Important to set state after view init to set action icons
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
      widget.onUpdateUI?.call();
    });
    super.initState();
  }

  @override
  void dispose() {
    _bottomBarScrollCtrl.dispose();
    super.dispose();
  }

  /// Opens a bottom sheet to adjust the line weight when drawing.
  void openLineWeightBottomSheet() {
    _imageKey.currentState!.showRangeSlider();
  }

  /// Sets the fill mode for drawing elements.
  /// When the `fill` parameter is `true`, drawing elements will be filled; otherwise, they will be outlined.
  void setFill(bool fill) {
    _imageKey.currentState?.setFill(fill);
    setState(() {});
    widget.onUpdateUI?.call();
  }

  /// Toggles the fill mode.
  void toggleFill() {
    _fill = !_fill;
    setFill(_fill);
  }

  /// Set the PaintMode for the current state and trigger an update if provided.
  void setMode(PaintModeE mode) {
    if (_imageKey.currentState != null) {
      _imageKey.currentState!.mode = mode;
    }
    widget.onUpdateUI?.call();
  }

  /// Undoes the last action performed in the painting editor.
  void undoAction() {
    _imageKey.currentState!.undo();
    setState(() {});
    widget.onUpdateUI?.call();
  }

  /// Redoes the previously undone action in the painting editor.
  void redoAction() {
    _imageKey.currentState!.redo();
    setState(() {});
    widget.onUpdateUI?.call();
  }

  /// Closes the editor without applying changes.
  void close() {
    Navigator.pop(context);
  }

  /// Finishes editing in the painting editor and returns the painted items as a result.
  /// If no changes have been made, it closes the editor without returning any changes.
  void done() async {
    if (!_imageKey.currentState!.canUndo) return Navigator.pop(context);
    Navigator.of(context).pop(_imageKey.currentState?.exportPaintedItems());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: imageEditorTheme.uiOverlayStyle,
      child: Theme(
        data: widget.theme.copyWith(
            tooltipTheme:
                widget.theme.tooltipTheme.copyWith(preferBelow: true)),
        child: LayoutBuilder(builder: (context, constraints) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            extendBodyBehindAppBar: true,
            backgroundColor: imageEditorTheme.paintingEditor.background,
            key: _key,
            appBar: _buildAppBar(constraints),
            body: _buildBody(),
            bottomNavigationBar: _buildBottomBar(),
          );
        }),
      ),
    );
  }

  /// Builds the app bar for the painting editor.
  /// Returns a [PreferredSizeWidget] representing the app bar.
  PreferredSizeWidget? _buildAppBar(BoxConstraints constraints) {
    return customWidgets.appBarPaintingEditor ??
        (imageEditorTheme.editorMode == ThemeEditorMode.simple
            ? AppBar(
                automaticallyImplyLeading: false,
                backgroundColor:
                    imageEditorTheme.paintingEditor.appBarBackgroundColor,
                foregroundColor:
                    imageEditorTheme.paintingEditor.appBarForegroundColor,
                actions: [
                  IconButton(
                    tooltip: i18n.paintEditor.back,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    icon: Icon(icons.backButton),
                    onPressed: close,
                  ),
                  if (_imageKey.currentState != null) ...[
                    if (constraints.maxWidth >= 300) ...[
                      if (constraints.maxWidth >= 380)
                        const SizedBox(width: 80),
                      const Spacer(),
                      if (paintEditorConfigs.canChangeLineWidth)
                        IconButton(
                          tooltip: i18n.paintEditor.lineWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          icon: Icon(
                            icons.paintingEditor.lineWeight,
                            color: Colors.white,
                          ),
                          onPressed: openLineWeightBottomSheet,
                        ),
                      if (paintEditorConfigs.canToggleFill)
                        IconButton(
                          tooltip: i18n.paintEditor.toggleFill,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          icon: Icon(
                            !_fill
                                ? icons.paintingEditor.noFill
                                : icons.paintingEditor.fill,
                            color: Colors.white,
                          ),
                          onPressed: toggleFill,
                        ),
                      if (constraints.maxWidth >= 380) const Spacer(),
                      IconButton(
                        tooltip: i18n.paintEditor.undo,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        icon: Icon(
                          icons.undoAction,
                          color: canUndo
                              ? Colors.white
                              : Colors.white.withAlpha(80),
                        ),
                        onPressed: undoAction,
                      ),
                      IconButton(
                        tooltip: i18n.paintEditor.redo,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        icon: Icon(
                          icons.redoAction,
                          color: canRedo
                              ? Colors.white
                              : Colors.white.withAlpha(80),
                        ),
                        onPressed: redoAction,
                      ),
                      _buildDoneBtn(),
                    ] else ...[
                      const Spacer(),
                      _buildDoneBtn(),
                      PlatformPopupBtn(
                        designMode: designMode,
                        title: i18n.paintEditor.smallScreenMoreTooltip,
                        options: [
                          if (paintEditorConfigs.canChangeLineWidth)
                            PopupMenuOption(
                              label: i18n.paintEditor.lineWidth,
                              icon: Icon(
                                icons.paintingEditor.lineWeight,
                              ),
                              onTap: openLineWeightBottomSheet,
                            ),
                          if (paintEditorConfigs.canToggleFill)
                            PopupMenuOption(
                              label: i18n.paintEditor.toggleFill,
                              icon: Icon(
                                !_fill
                                    ? icons.paintingEditor.noFill
                                    : icons.paintingEditor.fill,
                              ),
                              onTap: () {
                                _fill = !_fill;
                                setFill(_fill);
                                if (designMode ==
                                    ImageEditorDesignModeE.cupertino) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          if (_imageKey.currentState!.canUndo)
                            PopupMenuOption(
                              label: i18n.paintEditor.undo,
                              icon: Icon(
                                icons.undoAction,
                              ),
                              onTap: undoAction,
                            ),
                          if (_imageKey.currentState!.canRedo)
                            PopupMenuOption(
                              label: i18n.paintEditor.redo,
                              icon: Icon(
                                icons.redoAction,
                              ),
                              onTap: redoAction,
                            ),
                        ],
                      ),
                    ],
                  ],
                ],
              )
            : null);
  }

  /// Builds and returns an IconButton for applying changes.
  Widget _buildDoneBtn() {
    return IconButton(
      tooltip: i18n.paintEditor.done,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      icon: Icon(icons.applyChanges),
      iconSize: 28,
      onPressed: done,
    );
  }

  /// Builds the main body of the painting editor.
  /// Returns a [Widget] representing the editor's body.
  Widget _buildBody() {
    return SafeArea(
      child: Theme(
        data: widget.theme,
        child: Material(
          color: Colors.transparent,
          textStyle: platformTextStyle(context, designMode),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              TransformedContentGenerator(
                configs: widget.transformConfigs ?? TransformConfigs.empty(),
                child: ImageWithMultipleFilters(
                  width: widget.imageSize.width,
                  height: widget.imageSize.height,
                  designMode: designMode,
                  image: EditorImage(
                    assetPath: widget.assetPath,
                    byteArray: widget.byteArray,
                    file: widget.file,
                    networkUrl: widget.networkUrl,
                  ),
                  filters: widget.filters,
                  blur: widget.blur,
                ),
              ),
              if (widget.layers != null)
                LayerStack(
                  configs: widget.configs,
                  layers: widget.layers!,
                  paddingHelper: widget.paddingHelper,
                ),
              _buildPainter(),
              if (paintEditorConfigs.showColorPicker) _buildColorPicker(),
              if (imageEditorTheme.editorMode == ThemeEditorMode.whatsapp) ...[
                WhatsAppPaintBottomBar(
                  configs: widget.configs,
                  strokeWidth: _imageKey.currentState?.strokeWidth ?? 0.0,
                  onSetLineWidth: (val) {
                    setState(() {
                      _imageKey.currentState!.setStrokeWidth(val);
                    });
                  },
                ),
                WhatsAppPaintAppBar(
                  configs: widget.configs,
                  canUndo: canUndo,
                  onDone: done,
                  onTapUndo: undoAction,
                  onClose: close,
                  activeColor: activeColor,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the bottom navigation bar of the painting editor.
  /// Returns a [Widget] representing the bottom navigation bar.
  Widget? _buildBottomBar() {
    if (paintModes.length <= 1) return const SizedBox.shrink();
    return customWidgets.bottomBarPaintingEditor ??
        (imageEditorTheme.editorMode == ThemeEditorMode.simple
            ? Theme(
                data: widget.theme,
                child: Scrollbar(
                  controller: _bottomBarScrollCtrl,
                  scrollbarOrientation: ScrollbarOrientation.top,
                  thickness: isDesktop ? null : 0,
                  child: BottomAppBar(
                    height: kToolbarHeight,
                    color: imageEditorTheme.paintingEditor.bottomBarColor,
                    padding: EdgeInsets.zero,
                    child: Center(
                      child: SingleChildScrollView(
                        controller: _bottomBarScrollCtrl,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth:
                                min(MediaQuery.of(context).size.width, 500),
                            maxWidth: 500,
                          ),
                          child: Wrap(
                            direction: Axis.horizontal,
                            alignment: WrapAlignment.spaceAround,
                            children: <Widget>[
                              ...List.generate(
                                paintModes.length,
                                (index) => Builder(
                                  builder: (_) {
                                    var item = paintModes[index];
                                    var color = _imageKey.currentState?.mode ==
                                            item.mode
                                        ? imageEditorTheme.paintingEditor
                                            .bottomBarActiveItemColor
                                        : imageEditorTheme.paintingEditor
                                            .bottomBarInactiveItemColor;

                                    return FlatIconTextButton(
                                      label: Text(
                                        item.label,
                                        style: TextStyle(
                                            fontSize: 10.0, color: color),
                                      ),
                                      icon: Icon(item.icon, color: color),
                                      onPressed: () {
                                        setMode(item.mode);
                                        setState(() {});
                                        widget.onUpdateUI?.call();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null);
  }

  /// Builds the painting canvas for the editor.
  /// Returns a [Widget] representing the painting canvas.
  Widget _buildPainter() {
    return PaintingCanvas.autoSource(
      key: _imageKey,
      file: _editorImage.file,
      networkUrl: _editorImage.networkUrl,
      byteArray: _editorImage.byteArray,
      assetPath: _editorImage.assetPath,
      i18n: i18n,
      icons: icons,
      theme: widget.theme,
      designMode: designMode,
      imageSize: widget.imageSize,
      imageEditorTheme: imageEditorTheme,
      configs: paintEditorConfigs,
      onUpdate: () {
        setState(() {});
        widget.onUpdateUI?.call();
      },
    );
  }

  /// Builds the color picker widget for selecting colors while painting.
  /// Returns a [Widget] representing the color picker.
  Widget _buildColorPicker() {
    return Positioned(
      top: imageEditorTheme.editorMode == ThemeEditorMode.simple ? 10 : 60,
      right: 0,
      child: BarColorPicker(
        configs: widget.configs,
        length: min(
          imageEditorTheme.editorMode == ThemeEditorMode.simple ? 350 : 200,
          MediaQuery.of(context).size.height -
              MediaQuery.of(context).viewInsets.bottom -
              kToolbarHeight -
              kBottomNavigationBarHeight -
              MediaQuery.of(context).padding.top -
              30,
        ),
        horizontal: false,
        thumbColor: Colors.white,
        cornerRadius: 10,
        pickMode: PickMode.color,
        initialColor: paintEditorConfigs.initialColor,
        colorListener: (int value) {
          _imageKey.currentState?.setColor(value);
          setState(() {});
        },
      ),
    );
  }
}
