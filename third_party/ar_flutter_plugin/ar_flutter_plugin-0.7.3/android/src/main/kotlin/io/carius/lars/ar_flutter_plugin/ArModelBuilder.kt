package io.carius.lars.ar_flutter_plugin

import android.R
import android.app.Activity
import android.content.Context
import com.google.ar.sceneform.Node
import com.google.ar.sceneform.math.Vector3
import com.google.ar.sceneform.math.Quaternion
import com.google.ar.sceneform.assets.RenderableSource

import java.util.concurrent.CompletableFuture
import android.net.Uri
import android.view.Gravity
import android.widget.Toast
import com.google.ar.core.*
import com.google.ar.sceneform.ArSceneView
import com.google.ar.sceneform.FrameTime
import com.google.ar.sceneform.math.MathHelper
import com.google.ar.sceneform.rendering.*
import com.google.ar.sceneform.utilities.Preconditions
import com.google.ar.sceneform.ux.*

import io.carius.lars.ar_flutter_plugin.Serialization.*

import io.flutter.FlutterInjector
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.AccessController


// Responsible for creating Renderables and Nodes
class ArModelBuilder {

    // Creates feature point node
    fun makeFeaturePointNode(context: Context, xPos: Float, yPos: Float, zPos: Float): Node {
        val featurePoint = Node()                 
        var cubeRenderable: ModelRenderable? = null      
        MaterialFactory.makeOpaqueWithColor(context, Color(android.graphics.Color.YELLOW))
        .thenAccept { material ->
            val vector3 = Vector3(0.01f, 0.01f, 0.01f)
            cubeRenderable = ShapeFactory.makeCube(vector3, Vector3(xPos, yPos, zPos), material)
            cubeRenderable?.isShadowCaster = false
            cubeRenderable?.isShadowReceiver = false
        }
        featurePoint.renderable = cubeRenderable

        return featurePoint
    }

    // Creates a coordinate system model at the world origin (X-axis: red, Y-axis: green, Z-axis:blue)
    // The code for this function is adapted from Alexander's stackoverflow answer (https://stackoverflow.com/questions/48908358/arcore-how-to-display-world-origin-or-axes-in-debug-mode) 
    fun makeWorldOriginNode(context: Context): Node {
        val axisSize = 0.1f
        val axisRadius = 0.005f

        val rootNode = Node()
        val xNode = Node()
        val yNode = Node()
        val zNode = Node()

        rootNode.addChild(xNode)
        rootNode.addChild(yNode)
        rootNode.addChild(zNode)

        xNode.worldPosition = Vector3(axisSize / 2, 0f, 0f)
        xNode.worldRotation = Quaternion.axisAngle(Vector3(0f, 0f, 1f), 90f)

        yNode.worldPosition = Vector3(0f, axisSize / 2, 0f)

        zNode.worldPosition = Vector3(0f, 0f, axisSize / 2)
        zNode.worldRotation = Quaternion.axisAngle(Vector3(1f, 0f, 0f), 90f)

        MaterialFactory.makeOpaqueWithColor(context, Color(255f, 0f, 0f))
                .thenAccept { redMat ->
                    xNode.renderable = ShapeFactory.makeCylinder(axisRadius, axisSize, Vector3.zero(), redMat)
                }

        MaterialFactory.makeOpaqueWithColor(context, Color(0f, 255f, 0f))
                .thenAccept { greenMat ->
                    yNode.renderable = ShapeFactory.makeCylinder(axisRadius, axisSize, Vector3.zero(), greenMat)
                }

        MaterialFactory.makeOpaqueWithColor(context, Color(0f, 0f, 255f))
                .thenAccept { blueMat ->
                    zNode.renderable = ShapeFactory.makeCylinder(axisRadius, axisSize, Vector3.zero(), blueMat)
                }

        return rootNode
    }

    // Creates a node form a given gltf model path or URL. The gltf asset loading in Scenform is asynchronous, so the function returns a completable future of type Node
    fun makeNodeFromGltf(context: Context, transformationSystem: TransformationSystem, objectManagerChannel: MethodChannel, enablePans: Boolean, enableRotation: Boolean, name: String, modelPath: String, transformation: ArrayList<Double>): CompletableFuture<CustomTransformableNode> {
        val completableFutureNode: CompletableFuture<CustomTransformableNode> = CompletableFuture()

        val gltfNode = CustomTransformableNode(transformationSystem, objectManagerChannel, enablePans, enableRotation)

        ModelRenderable.builder()
                .setSource(context, RenderableSource.builder().setSource(
                        context,
                        Uri.parse(modelPath),
                        RenderableSource.SourceType.GLTF2)
                        .build())
                .setRegistryId(modelPath)
                .build()
                .thenAccept{ renderable ->
                    gltfNode.renderable = renderable
                    gltfNode.name = name
                    val transform = deserializeMatrix4(transformation)
                    gltfNode.worldScale = transform.first
                    gltfNode.worldPosition = transform.second
                    gltfNode.worldRotation = transform.third
                    completableFutureNode.complete(gltfNode)
                }
                .exceptionally { throwable ->
                    completableFutureNode.completeExceptionally(throwable)
                    null // return null because java expects void return (in java, void has no instance, whereas in Kotlin, this closure returns a Unit which has one instance)
                }

    return completableFutureNode
    }

    fun makeLaksaBowlNode(context: Context, transformationSystem: TransformationSystem, objectManagerChannel: MethodChannel, enablePans: Boolean, enableRotation: Boolean, name: String, transformation: ArrayList<Double>): CompletableFuture<CustomTransformableNode> {
        val completableFutureNode: CompletableFuture<CustomTransformableNode> = CompletableFuture()
        val rootNode = CustomTransformableNode(transformationSystem, objectManagerChannel, enablePans, enableRotation)

        val bowlMaterialFuture = MaterialFactory.makeOpaqueWithColor(context, Color(android.graphics.Color.rgb(244, 222, 186)))
        val brothMaterialFuture = MaterialFactory.makeOpaqueWithColor(context, Color(android.graphics.Color.rgb(235, 92, 34)))
        val noodleMaterialFuture = MaterialFactory.makeOpaqueWithColor(context, Color(android.graphics.Color.rgb(250, 230, 172)))
        val herbMaterialFuture = MaterialFactory.makeOpaqueWithColor(context, Color(android.graphics.Color.rgb(38, 140, 52)))
        val chilliMaterialFuture = MaterialFactory.makeOpaqueWithColor(context, Color(android.graphics.Color.rgb(205, 30, 22)))

        CompletableFuture.allOf(
                bowlMaterialFuture,
                brothMaterialFuture,
                noodleMaterialFuture,
                herbMaterialFuture,
                chilliMaterialFuture
        ).thenAccept {
            val bowl = Node()
            bowl.renderable = ShapeFactory.makeCylinder(0.32f, 0.16f, Vector3.zero(), bowlMaterialFuture.get())
            bowl.localPosition = Vector3(0f, -0.04f, 0f)
            bowl.localScale = Vector3(1.35f, 0.45f, 1.0f)
            bowl.setParent(rootNode)

            val broth = Node()
            broth.renderable = ShapeFactory.makeCylinder(0.31f, 0.02f, Vector3.zero(), brothMaterialFuture.get())
            broth.localPosition = Vector3(0f, 0.045f, 0f)
            broth.localScale = Vector3(1.22f, 1.0f, 0.9f)
            broth.setParent(rootNode)

            for (i in -3..3) {
                val noodle = Node()
                noodle.renderable = ShapeFactory.makeCylinder(0.012f, 0.48f, Vector3.zero(), noodleMaterialFuture.get())
                noodle.localPosition = Vector3(0.02f * i, 0.08f, 0.015f * (i % 2))
                noodle.localRotation = Quaternion.axisAngle(Vector3(0f, 1f, 0f), 82f + (i * 5f))
                noodle.setParent(rootNode)
            }

            for (i in 0..3) {
                val herb = Node()
                herb.renderable = ShapeFactory.makeCube(Vector3(0.11f, 0.012f, 0.035f), Vector3.zero(), herbMaterialFuture.get())
                herb.localPosition = Vector3(-0.12f + (0.08f * i), 0.105f, -0.05f + (0.035f * i))
                herb.localRotation = Quaternion.axisAngle(Vector3(0f, 1f, 0f), 20f + (i * 55f))
                herb.setParent(rootNode)
            }

            for (i in 0..2) {
                val chilli = Node()
                chilli.renderable = ShapeFactory.makeCylinder(0.025f, 0.01f, Vector3.zero(), chilliMaterialFuture.get())
                chilli.localPosition = Vector3(-0.08f + (0.08f * i), 0.12f, 0.08f - (0.04f * i))
                chilli.localRotation = Quaternion.axisAngle(Vector3(1f, 0f, 0f), 90f)
                chilli.setParent(rootNode)
            }

            rootNode.name = name
            val transform = deserializeMatrix4(transformation)
            rootNode.worldScale = transform.first
            rootNode.worldPosition = transform.second
            rootNode.worldRotation = transform.third
            completableFutureNode.complete(rootNode)
        }.exceptionally { throwable ->
            completableFutureNode.completeExceptionally(throwable)
            null
        }

        return completableFutureNode
    }

    // Creates a node form a given glb model path or URL. The gltf asset loading in Sceneform is asynchronous, so the function returns a compleatable future of type Node
    fun makeNodeFromGlb(context: Context, transformationSystem: TransformationSystem, objectManagerChannel: MethodChannel, enablePans: Boolean, enableRotation: Boolean, name: String, modelPath: String, transformation: ArrayList<Double>): CompletableFuture<CustomTransformableNode> {
        val completableFutureNode: CompletableFuture<CustomTransformableNode> = CompletableFuture()

        val gltfNode = CustomTransformableNode(transformationSystem, objectManagerChannel, enablePans, enableRotation)
        //gltfNode.scaleController.isEnabled = false
        //gltfNode.translationController.isEnabled = false

        /*gltfNode.removeTransformationController(translationController)
        gltfNode.addTra
        val customTranslationController = DragController(
            gltfNode,
            transformationSystem.dragRecognizer,
            objectManagerChannel,
            transformationSystem
        )*/

        ModelRenderable.builder()
                .setSource(context, RenderableSource.builder().setSource(
                        context,
                        Uri.parse(modelPath),
                        RenderableSource.SourceType.GLB)
                        .build())
                .setRegistryId(modelPath)
                .build()
                .thenAccept{ renderable ->
                    gltfNode.renderable = renderable
                    gltfNode.name = name
                    val transform = deserializeMatrix4(transformation)
                    gltfNode.worldScale = transform.first
                    gltfNode.worldPosition = transform.second
                    gltfNode.worldRotation = transform.third
                    completableFutureNode.complete(gltfNode)
                }
                .exceptionally{throwable ->
                    completableFutureNode.completeExceptionally(throwable)
                    null // return null because java expects void return (in java, void has no instance, whereas in Kotlin, this closure returns a Unit which has one instance)
                }

        return completableFutureNode
    }
}

class CustomTransformableNode(transformationSystem: TransformationSystem, objectManagerChannel: MethodChannel, enablePans: Boolean, enableRotation: Boolean) :
    TransformableNode(transformationSystem) { //

    private lateinit var customTranslationController: CustomTranslationController

    private lateinit var customRotationController: CustomRotationController

    init {
        // Remove standard controllers
        translationController.isEnabled = false
        rotationController.isEnabled = false
        scaleController.isEnabled = false
        removeTransformationController(translationController)
        removeTransformationController(rotationController)
        removeTransformationController(scaleController)


        // Add custom controllers if needed
        if (enablePans) {
            customTranslationController = CustomTranslationController(
                this,
                transformationSystem.dragRecognizer,
                objectManagerChannel
            )
            addTransformationController(customTranslationController)
        }
        if (enableRotation) {
            customRotationController = CustomRotationController(
                this,
                transformationSystem.twistRecognizer,
                objectManagerChannel
            )
            addTransformationController(customRotationController)
        }
    }
}

class CustomTranslationController(transformableNode: BaseTransformableNode, gestureRecognizer: DragGestureRecognizer, objectManagerChannel: MethodChannel) :
    TranslationController(transformableNode, gestureRecognizer) {

    val platformChannel: MethodChannel = objectManagerChannel

    override fun canStartTransformation(gesture: DragGesture): Boolean {
        platformChannel.invokeMethod("onPanStart", transformableNode.name)
        super.canStartTransformation(gesture)
        return transformableNode.isSelected
    }

    override fun onContinueTransformation(gesture: DragGesture) {
        platformChannel.invokeMethod("onPanChange", transformableNode.name)
        super.onContinueTransformation(gesture)
        }

    override fun onEndTransformation(gesture: DragGesture) {
        val serializedLocalTransformation = serializeLocalTransformation(transformableNode)
        platformChannel.invokeMethod("onPanEnd", serializedLocalTransformation)
        super.onEndTransformation(gesture)
     }
}

class CustomRotationController(transformableNode: BaseTransformableNode, gestureRecognizer: TwistGestureRecognizer, objectManagerChannel: MethodChannel) :
    RotationController(transformableNode, gestureRecognizer) {

    val platformChannel: MethodChannel = objectManagerChannel

    override fun canStartTransformation(gesture: TwistGesture): Boolean {
        platformChannel.invokeMethod("onRotationStart", transformableNode.name)
        super.canStartTransformation(gesture)
        return transformableNode.isSelected
    }

    override fun onContinueTransformation(gesture: TwistGesture) {
        platformChannel.invokeMethod("onRotationChange", transformableNode.name)
        super.onContinueTransformation(gesture)
    }

    override fun onEndTransformation(gesture: TwistGesture) {
        val serializedLocalTransformation = serializeLocalTransformation(transformableNode)
        platformChannel.invokeMethod("onRotationEnd", serializedLocalTransformation)
        super.onEndTransformation(gesture)
     }
}
