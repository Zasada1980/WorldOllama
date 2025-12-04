// Desktop Automation - Integration Tests
// ЭТАП 1.1: Базовая проверка crates для агента консоли VS Code

#[cfg(test)]
mod integration_tests {
    use super::super::*;

    /// Test 1: enigo initialization (mouse/keyboard simulation)
    #[test]
    fn test_enigo_init() {
        // Проверка: enigo можно создать без паники
        let result = std::panic::catch_unwind(|| {
            let _enigo = enigo::Enigo::new(&enigo::Settings::default());
        });
        assert!(result.is_ok(), "enigo initialization failed");
    }

    /// Test 2: accesskit usage check (Accessibility Tree API)
    #[test]
    fn test_accesskit_types() {
        // Проверка: accesskit типы доступны
        use accesskit::{NodeId, Role};
        
        let node_id = NodeId(42);
        let role = Role::Button;
        
        assert_eq!(node_id.0, 42);
        assert_eq!(role, Role::Button);
    }

    /// Test 3: notify watcher initialization (file system monitoring)
    #[test]
    fn test_notify_init() {
        use notify::{RecommendedWatcher, Watcher};
        use std::sync::mpsc::channel;
        
        let (tx, _rx) = channel();
        let result = RecommendedWatcher::new(
            move |_res| { let _ = tx.send(()); },
            notify::Config::default()
        );
        
        assert!(result.is_ok(), "notify watcher creation failed");
    }

    /// Test 4: screenshots capture (basic initialization)
    #[test]
    fn test_screenshots_available() {
        // Проверка: screenshots API доступен
        let screens = screenshots::Screen::all();
        assert!(screens.is_ok(), "screenshots::Screen::all() failed");
    }

    /// Test 5: image processing (PNG handling)
    #[test]
    fn test_image_types() {
        use image::{ImageBuffer, Rgba};
        
        // Создаём минимальное изображение 1x1
        let img: ImageBuffer<Rgba<u8>, Vec<u8>> = ImageBuffer::new(1, 1);
        assert_eq!(img.width(), 1);
        assert_eq!(img.height(), 1);
    }
}
