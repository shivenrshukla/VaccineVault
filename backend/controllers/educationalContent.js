import EducationalContent from "../models/EducationalContent.js";

export const createEducationalContent = async (req, res) => {
    try {
        const { title, description, contentType, url } = req.body;
        const adminId = req.user.id; // Assuming req.user contains the authenticated admin's info

        const newContent = await EducationalContent.create({
            title,
            description,
            contentType,
            url,
            adminId
        });

        res.status(201).json(newContent);
    } catch (error) {
        console.error("Error creating educational content:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

export const getAllEducationalContents = async (req, res) => {
    try {
        const contents = await EducationalContent.findAll();
        res.status(200).json(contents);
    } catch (error) {
        console.error("Error fetching educational contents:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

export const getEducationalContentById = async (req, res) => {
    try {
        const { id } = req.params;
        const content = await EducationalContent.findByPk(id);

        if (!content) {
            return res.status(404).json({ message: "Content not found" });
        }

        res.status(200).json(content);
    } catch (error) {
        console.error("Error fetching educational content:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

export const updateEducationalContent = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, contentType, url } = req.body;

        const content = await EducationalContent.findByPk(id);
        if (!content) {
            return res.status(404).json({ message: "Content not found" });
        }

        // Ensure only the admin who created the content can update it
        if (content.adminId !== req.user.id) {
            return res.status(403).json({ message: "Forbidden" });
        }

        content.title = title || content.title;
        content.description = description || content.description;
        content.contentType = contentType || content.contentType;
        content.url = url || content.url;

        await content.save();
        res.status(200).json(content);
    } catch (error) {
        console.error("Error updating educational content:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

export const deleteEducationalContent = async (req, res) => {
    try {
        const { id } = req.params;

        const content = await EducationalContent.findByPk(id);
        if (!content) {
            return res.status(404).json({ message: "Content not found" });
        }

        // Ensure only the admin who created the content can delete it
        if (content.adminId !== req.user.id) {
            return res.status(403).json({ message: "Forbidden" });
        }

        await content.destroy();
        res.status(200).json({ message: "Content deleted successfully" });
    } catch (error) {
        console.error("Error deleting educational content:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

export const getContentsByAdmin = async (req, res) => {
    try {
        const adminId = req.user.id; // Assuming req.user contains the authenticated admin's info
        const contents = await EducationalContent.findAll({ where: { adminId } });
        res.status(200).json(contents);
    } catch (error) {
        console.error("Error fetching admin's educational contents:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};